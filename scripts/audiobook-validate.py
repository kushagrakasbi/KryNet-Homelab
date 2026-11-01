#!/usr/bin/env python3
"""
Audiobook Ecosystem & Library Validation Script
Audits KryNet's audiobook library structure, ASIN uniqueness, and service health.

Usage:
    python3 scripts/audiobook-validate.py
"""

import os
import re
import sys
import subprocess
import urllib.request
import urllib.error

PRIME_SSH = "prime"
AUDIOBOOKS_DIR = "/mnt/andromeda/media/audiobooks"
ABS_URL = "http://192.168.0.100:13378/healthcheck"
CHAPTARR_URL = "http://192.168.0.100:8789/ping"

def run_ssh(host, cmd, stdin_input=None):
    try:
        args = ["ssh", "-o", "ConnectTimeout=5", host]
        if cmd:
            args.append(cmd)
        res = subprocess.run(
            args,
            input=stdin_input,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        return res.stdout.strip()
    except subprocess.CalledProcessError as e:
        return None

def check_service_health(name, url):
    print(f"[*] Checking {name} ({url})...")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "KryNet-Validator"})
        with urllib.request.urlopen(req, timeout=5) as resp:
            if resp.status in (200, 204):
                print(f"  [OK] {name} is healthy (HTTP {resp.status})")
                return True
            else:
                print(f"  [FAIL] {name} returned HTTP {resp.status}")
                return False
    except Exception as e:
        print(f"  [FAIL] {name} unreachable: {e}")
        return False

def audit_library_on_prime():
    print(f"\n[*] Auditing audiobook library on Prime ({AUDIOBOOKS_DIR})...")
    remote_script = f"""
import os, re

base = '{AUDIOBOOKS_DIR}'
asin_re = re.compile(r'\\[([A-Z0-9]{{10}})\\]')

asins = {{}}
hyphen_dirs = []
total_authors = 0
total_books = 0

for author in os.listdir(base):
    author_path = os.path.join(base, author)
    if os.path.isdir(author_path) and not author.startswith('.'):
        total_authors += 1

for root, dirs, files in os.walk(base):
    for d in dirs:
        if d.startswith('- '):
            hyphen_dirs.append(os.path.join(root, d))
        m = asin_re.search(d)
        if m:
            total_books += 1
            asin = m.group(1)
            asins.setdefault(asin, []).append(os.path.join(root, d))

dups = {{k: v for k, v in asins.items() if len(v) > 1}}
print(f"AUTHORS={{total_authors}}")
print(f"BOOKS={{total_books}}")
print(f"DUPLICATES={{len(dups)}}")
for k, v in dups.items():
    print(f"DUP_ASIN: {{k}} -> {{v}}")
print(f"HYPHEN_DIRS={{len(hyphen_dirs)}}")
for hd in hyphen_dirs:
    print(f"HYPHEN_DIR: {{hd}}")
"""
    output = run_ssh(PRIME_SSH, "python3", stdin_input=remote_script)
    if not output:
        print("  [FAIL] Could not query Prime over SSH.")
        return False

    duplicates = 0
    hyphens = 0
    for line in output.splitlines():
        if line.startswith("AUTHORS="):
            print(f"  [INFO] Total author directories: {line.split('=')[1]}")
        elif line.startswith("BOOKS="):
            print(f"  [INFO] Total books with ASIN: {line.split('=')[1]}")
        elif line.startswith("DUPLICATES="):
            duplicates = int(line.split("=")[1])
            if duplicates == 0:
                print("  [OK] Duplicate ASINs: 0")
            else:
                print(f"  [FAIL] Duplicate ASINs detected: {duplicates}")
        elif line.startswith("DUP_ASIN:"):
            print(f"    - {line}")
        elif line.startswith("HYPHEN_DIRS="):
            hyphens = int(line.split("=")[1])
            if hyphens == 0:
                print("  [OK] Unwanted leading hyphen directories: 0")
            else:
                print(f"  [FAIL] Directories with leading hyphen detected: {hyphens}")
        elif line.startswith("HYPHEN_DIR:"):
            print(f"    - {line}")

    return duplicates == 0 and hyphens == 0

def check_libation_container():
    print("\n[*] Checking Libation service process on Prime...")
    out = run_ssh(PRIME_SSH, "ps aux | grep -iE '/libation/liberate|/libation/LibationCli' | grep -v grep")
    if out:
        print("  [OK] Libation background loop is active on Prime.")
        return True
    else:
        print("  [WARN] No active Libation process found on Prime.")
        return False

def main():
    print("=" * 60)
    print("KryNet Audiobook Ecosystem Validation")
    print("=" * 60)

    abs_ok = check_service_health("Audiobookshelf", ABS_URL)
    chaptarr_ok = check_service_health("Chaptarr", CHAPTARR_URL)
    libation_ok = check_libation_container()
    lib_ok = audit_library_on_prime()

    print("\n" + "=" * 60)
    if abs_ok and chaptarr_ok and libation_ok and lib_ok:
        print("RESULT: ALL AUDIOBOOK CHECKS PASSED (HEALTHY)")
        print("=" * 60)
        sys.exit(0)
    else:
        print("RESULT: ONE OR MORE CHECKS FAILED OR WARNED")
        print("=" * 60)
        sys.exit(1)

if __name__ == "__main__":
    main()
