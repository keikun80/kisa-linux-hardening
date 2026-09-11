#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
callbacks/results_json.py 가 뿌린 NDJSON 이벤트를 모아
'호스트 x U-ID' 감사 표를 만든다.

판정 규칙 (호스트 x ID):
  ERROR  : 그 ID 태스크에서 실패(failed/item_failed) 이벤트
  CHG    : changed / item_changed 가 있다면 '개선 필요(변경 예정)'
  INFO   : 태스크명이 [U-XX:M] 형태면 기계 판정 불가(사람 확인) —
           changed 와 상관없이 INFO 로 상향(변경이 나도 정보성)
  OK     : 나머지 (전부 ok)
"""

import argparse
import csv
import json
import os
import re
import sys
from collections import defaultdict

_ID_RE = re.compile(r"\[\s*(U-\d{2})\s*(:M)?\s*\]")


def parse_event_line(raw):
    line = raw.strip()
    if not line.startswith("{"):
        return None
    try:
        return json.loads(line)
    except json.JSONDecodeError:
        return None


def extract_id(task):
    if not task:
        return None, False
    m = _ID_RE.search(str(task))
    if not m:
        return None, False
    return m.group(1), bool(m.group(2))


VERB_ORDER = {"failed": 3, "item_failed": 3, "changed": 2, "item_changed": 2,
              "ok": 0, "item_ok": 0, "skipped": 0}


class Cell:
    __slots__ = ("best", "manual", "details", "msgs")

    def __init__(self):
        self.best = 0          # 최고 심각도 verb 랭크
        self.manual = False
        self.details = []      # 대표 샘플 몇 개
        self.msgs = []

    def feed(self, ev):
        rank = VERB_ORDER.get(ev, 0)
        self.best = max(self.best, rank)
        item = ev.get("item")
        if item and len(self.details) < 8:
            self.details.append(str(item))
        msg = ev.get("msg")
        if msg and len(self.msgs) < 4:
            self.msgs.append(msg.replace("\n", " ")[:120])

    @property
    def grade(self):
        if self.best >= 3:
            return "ERROR"
        if self.manual:
            return "INFO"
        if self.best == 2:
            return "CHG"
        return "OK"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--ndjson", required=True)
    ap.add_argument("--outdir", required=True)
    ap.add_argument("--title", default="KISA 감사")
    args = ap.parse_args(argv)

    hosts_order = []
    cells = defaultdict(dict)      # host -> id -> Cell
    pb_started = False
    all_ids = []                    # 플레이 중 마주한 모든 U-IDs 수집

    with open(args.ndjson, encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            ev = parse_event_line(raw)
            if ev is None:
                continue
            etype = ev.get("ev")
            if etype == "pb_start":
                pb_started = True
                continue
            if etype not in ("ok", "changed", "failed", "skipped",
                             "item_ok", "item_changed", "item_failed"):
                continue
            host = ev.get("host")
            task = ev.get("task")
            if not host:
                continue
            if host not in hosts_order:
                hosts_order.append(host)
            uid, manual = extract_id(task)
            if not uid:
                continue
            all_ids.append(uid)
            cell = cells.setdefault(host, {}).setdefault(uid, Cell())
            if manual:
                cell.manual = True
            cell.feed(ev)

    # ID 정렬 (숫자순)
    def idnum(i):
        try:
            return int(i.split("-")[1])
        except Exception:
            return 999
    ids_sorted = sorted(sorted(all_ids), key=idnum)

    os.makedirs(args.outdir, exist_ok=True)

    # ---------- CSV: 상세 -----------------------------------------------
    csv_path = os.path.join(args.outdir, "detail.csv")
    with open(csv_path, "w", newline="", encoding="utf-8-sig") as fh:
        w = csv.writer(fh)
        w.writerow(["host"] + ids_sorted)
        for host in hosts_order:
            row = [host]
            for i in ids_sorted:
                cell = cells.get(host, {}).get(i)
                row.append(cell.grade if cell else "-")
            w.writerow(row)

    # ---------- SUMMARY.md: 읽기 좋은 표 -----------------------------------
    md = []
    md.append("# {}\n".format(args.title))
    md.append("범례: **CHG**(개선필요 / 변경 예정) · **ERROR**(오류) · "
              "**INFO**(사람 확인 필요) · **OK**(양호, 근사 판정) · `-`(해당 없음)\n")

    legend = {"CHG": "**CHG**", "ERROR": "**ERR**", "INFO": "INF", "OK": ".", "-": " "}
    widths = {}
    for i in ids_sorted:
        widths[i] = max(len("%02d" % idnum(i)), 3)

    hdr = "| host | " + " | ".join("U-%02d" % idnum(i) for i in ids_sorted) + " |"
    sep = "|------|" + "|".join(["----"] * len(ids_sorted)) + "|"
    md.append(hdr)
    md.append(sep)
    cnt = {"CHG": 0, "ERROR": 0, "INFO": 0, "OK": 0}
    for host in hosts_order:
        vals = []
        for i in ids_sorted:
            cell = cells.get(host, {}).get(i)
            g = "-" if cell is None else cell.grade
            if g in cnt:
                cnt[g] += 1
            short = {"CHG": "▲", "ERROR": "✗", "INFO": "◇", "OK": "·", "-": "."}[g]
            vals.append(short)
        md.append("| `{}` | {} |".format(host, " | ".join(vals)))

    md.append("")
    md.append("**요약:** {}".format(", ".join("{}={}개".format(k, v) for k, v in
                                                (("CHG", cnt["CHG"]),
                                                 ("ERROR", cnt["ERROR"]),
                                                 ("INFO", cnt["INFO"]),
                                                 ("OK", cnt["OK"])))))
    md.append("")

    # 세부: CHG/ERROR 셀의 이유 (상위 몇 개만)
    md.append("## 주요 변경 예정 / 오류 항목\n")
    any_detail = False
    for host in hosts_order:
        for i in ids_sorted:
            cell = cells.get(host, {}).get(i)
            if not cell or cell.grade not in ("CHG", "ERROR"):
                continue
            any_detail = True
            md.append("- **{} · {}: {}**".format(host, i, cell.grade))
            for d in cell.details[:5]:
                md.append("  - `{}`".format(d))
            for mm in cell.msgs[:3]:
                md.append("  - ⚠ {}".format(mm))
    if not any_detail:
        md.append("(변경 예정/오류 항목 없음 — 대상이 모두 양호 상태로 평가됨)")

    sum_path = os.path.join(args.outdir, "SUMMARY.md")
    with open(sum_path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(md) + "\n")

    print("[report] SUMMARY={} CSV={} hosts={} ids={}".format(
        sum_path, csv_path, len(hosts_order), len(ids_sorted)))
    if not pb_started:
        print("[report] !! playbook start 이벤트 없음 — callback 이 잡혔는지 확인", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
