#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Known contamination line repair."""
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent

# (file, anchor-must-appear-in-line, replacement-whole-line)
FIXES = [
    # (file, kind, locator, new-line)
    ("roles/kisa_linux_harden/tasks/accounts/u09_ghost_gid_membership.yml", "line", 30,
     '- name: "[U-09:M] Ghost member report(remove determined by person)"'),
    ("roles/kisa_linux_harden/tasks/accounts/u13_secure_hash_algo.yml", "line", 21,
     "      Remaining weak hashes (maintained until next password change):"),
    ("roles/kisa_linux_harden/tasks/files/u17_boot_scripts_perms.yml", "line", 3,
     "# Criterion: owned by root, unwritable by others"),
    ("roles/kisa_linux_harden/tasks/files/u26_dev_regular_files.yml", "line", 7,
     '- name: "[U-26] Listing of regular files inside /dev"'),
    ("roles/kisa_linux_harden/tasks/files/u30_umask_policy.yml", "line", 22,
     '- name: "[U-30:M] Query for current UMASK value in login.defs"'),
    ("roles/kisa_linux_harden/tasks/files/u33_hidden_files_audit.yml", "line", 2,
     "# U-33 Hidden files (starting with a dot) — search/manage"),
    ("roles/kisa_linux_harden/tasks/lifecycle/u64_recurring_security_patches.yml", "line", 5,
     "# Prohibit full upgrades (to prevent service degradation). Can be disabled with vu_autopatch_security=false."),
    ("roles/kisa_linux_harden/tasks/services/u48_expn_vrfy_limits.yml", "line", 2,
     "# U-48 Restrictions on EXPN/VRFY (user enumeration) commands"),
    ("roles/kisa_linux_harden/tasks/services/u56_ftp_access_control.yml", "line", 3,
     "# Only effective if vsftpd is installed."),
    ("scripts/report.py", "line", 89,
     "    all_ids = []                    # Collects all U-IDs encountered during play"),
]

def main():
    missed = []
    for rel, kind, loc, new_line in FIXES:
        p = BASE / rel
        lines = p.read_text(encoding="utf-8").split("\n")
        if kind == "line":
            lines[loc - 1] = new_line
        else:  # contains
            hit = -1
            for i, ln in enumerate(lines):
                if loc in ln:
                    hit = i
                    break
            if hit < 0:
                missed.append((rel, loc))
                continue
            lines[hit] = new_line
        p.write_text("\n".join(lines), encoding="utf-8")
    print("MISSED:", missed if missed else "none")

main()
