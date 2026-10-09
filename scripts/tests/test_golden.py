#!/usr/bin/env python3
"""Golden tests for hamra-init: determinism + golden comparison.

Runs the engine in --render-into mode (pure generation, no hardware probing,
no writes outside a temp dir) against every fixture in scripts/fixtures/*.json
and compares each file byte-for-byte with scripts/fixtures/golden/<name>/. Also
renders each fixture twice to prove determinism.
"""

import filecmp
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
FIXTURES = REPO / "scripts/fixtures"
GOLDEN = FIXTURES / "golden"
ENGINE = REPO / "scripts/hamra-init.py"


def render(fixture, outdir):
    r = subprocess.run(
        ["python3", str(ENGINE), "--answers", str(fixture), "--render-into", str(outdir)],
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        print(r.stderr)
        sys.exit(1)


def snapshot(directory):
    return {
        str(path.relative_to(directory)): path.read_bytes()
        for path in sorted(directory.rglob("*"))
        if path.is_file()
    }


def main():
    failures = 0
    fixtures = sorted(FIXTURES.glob("*.json"))
    if not fixtures:
        print("no fixtures found")
        sys.exit(1)

    for fixture in fixtures:
        name = fixture.stem
        golden_dir = GOLDEN / name

        with tempfile.TemporaryDirectory() as tmp:
            first, second = Path(tmp) / "a", Path(tmp) / "b"
            render(fixture, first)
            render(fixture, second)
            out1, out2 = snapshot(first), snapshot(second)
            if out1 != out2:
                print(f"FAIL {name}: not deterministic")
                failures += 1
                continue

        if not golden_dir.is_dir():
            print(f"FAIL {name}: missing golden dir {golden_dir}")
            failures += 1
            continue

        expected = snapshot(golden_dir)
        if out1 != expected:
            print(f"FAIL {name}: output differs from golden")
            print(f"--- golden files: {sorted(expected)}")
            print(f"--- generated files: {sorted(out1)}")
            for filename in sorted(set(expected) | set(out1)):
                if expected.get(filename) != out1.get(filename):
                    print(f"--- differs: {filename}")
            failures += 1
        else:
            print(f"PASS {name}")

    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
