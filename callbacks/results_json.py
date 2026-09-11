"""
KISA 감사 전용 NDJSON 콜백
========================
호스트 x 태스크(태스크명에 포함된 U-XX 태그) 단위로 이벤트를 JSON 라인을
STDOUT 에 흘려보낸다. scripts/report.py 가 이 라인을 집계하여
'양호 / 개선필요(변경 예정) / 오류' 테이블을 만든다.

활성은 플러그인 자동탐색(현재 디렉토리의 callbacks/)으로 이뤄지며,
설정 변경이 없다. 출력 자체는 표준 화면 출력을 방해하지 않는다.
"""

from __future__ import annotations

import json
import re
import sys

from ansible.plugins.callback import Base
from ansible.release import __version__


def _item_name(result):
    """루프 이벤트의 item 을 짧은 문자열로 압축."""
    it = result.get("item")
    if it is None:
        return None
    if isinstance(it, str):
        return it if len(it) <= 200 else it[:197] + "..."
    if isinstance(it, dict):
        # dict item 은 식별자에 가까운 키를 선호
        for k in ("path", "name", "item", "key", "dest"):
            if k in it:
                v = it[k]
                return (str(v)[:200])
        # dict 전체를 짧게 jsondump
        s = json.dumps(it, ensure_ascii=False, default=str)
        return s if len(s) <= 200 else s[:197] + "..."
    return str(it)[:200]


class CallbackModule(Base):
    CALLBACK_VERSION = 2.0
    NAME = "results_json"
    CALLBACK_NEEDS_WHATEVER = True

    def __init__(self):
        super().__init__()
        self.fd = sys.stderr  # STDERR 로 흘리면 ANSI 색상이 섞이는 STDOUT 로부터 격리

    # ---- play level ---------------------------------------------------------
    def v2_playbook_on_start(self, playbook):
        self._emit({"ev": "pb_start"})

    def v2_playbook_on_stats(self, stats):
        self._emit({"ev": "pb_end", "stats": self._norm_stats(stats)})

    @staticmethod
    def _norm_stats(stats):
        out = {}
        for host, st in getattr(stats, "process", {}).items():
            out[host] = {
                "ok": st.ok,
                "changed": st.changed,
                "failures": st.failures,
                "skipped": st.skipped,
            }
        return out

    # ---- runner level -------------------------------------------------------
    def _event(self, ev, result, extra=None):
        payload = {
            "ev": ev,
            "task": result.get("_task").get("name") if result.get("_task") else "?",
            "host": result.get("_host"),
        }
        if result.get("changed"):
            payload["changed"] = True
        if "msg" in result:
            payload["msg"] = str(result["msg"])[:300]
        if extra:
            payload.update(extra)
        self._emit(payload)

    def v2_runner_on_ok(self, result):
        self._event("ok", result, {"item": _item_name(result)})

    def v2_runner_on_failed(self, result):
        self._event("failed", result, {"item": _item_name(result)})

    def v2_runner_on_skipped(self, result):
        self._event("skipped", result)

    def v2_runner_item_on_ok(self, result):
        self._event("item_ok", result, {"item": _item_name(result)})

    def v2_runner_item_on_failed(self, result):
        self._event("item_failed", result, {"item": _item_name(result)})

    # changed 계열 (핵심: 이 이벤트가 곧 '개선 예정' 신호)
    def v2_runner_on_changed(self, result):
        self._event("changed", result, {"item": _item_name(result)})

    def v2_runner_item_on_changed(self, result):
        self._event("item_changed", result, {"item": _item_name(result)})

    # ------------------------------------------------------------------
    def _emit(self, obj):
        try:
            self.fd.write(json.dumps(obj, ensure_ascii=False, default=str) + "\n")
            self.fd.flush()
        except Exception:
            # 콜백 실패는 메인 플로우를 죽이지 않는다
            pass


_TAG_RE = re.compile(r"\[\s*(U-(\d{2}))\s*\]")


def parse_tag(task_name):
    """'[U-12] xyz' 형태의 태스크 네임을 뽑아온다. 없으면 None 을 반환"""
    if not task_name:
        return None, None
    m = _TAG_RE.search(str(task_name))
    return (m.group(1), m.group(2)) if m else (None, None)
