#!/usr/bin/env python3
"""Golden tests for hamra-init: determinism + golden comparison.

Runs the engine in --render-only mode (pure generation, no hardware probing,
no writes) against every fixture in scripts/fixtures/*.json and compares the
output byte-for-byte with scripts/fixtures/golden/<name>.nix. Also runs each
fixture twice to prove determinism.
"""

import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
FIXTURES = REPO / "scripts/fixtures"
GOLDEN = FIXTURES / "golden"
ENGINE = REPO / "scripts/hamra-init.py"


def render(fixture):
    r = subprocess.run(
        ["python3", str(ENGINE), "--answers", str(fixture), "--render-only"],
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        print(r.stderr)
        sys.exit(1)
    return r.stdout


def main():
    failures = 0
    fixtures = sorted(FIXTURES.glob("*.json"))
    if not fixtures:
        print("no fixtures found")
        sys.exit(1)

    for fixture in fixtures:
        name = fixture.stem
        golden_path = GOLDEN / f"{name}.nix"

        out1 = render(fixture)
        out2 = render(fixture)
        if out1 != out2:
            print(f"FAIL {name}: not deterministic")
            failures += 1
            continue

        if not golden_path.is_file():
            print(f"FAIL {name}: missing golden {golden_path}")
            failures += 1
            continue

        expected = golden_path.read_text()
        if out1 != expected:
            print(f"FAIL {name}: output differs from golden")
            print("--- golden ---")
            print(expected)
            print("--- generated ---")
            print(out1)
            failures += 1
        else:
            print(f"PASS {name}")

    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
