#!/usr/bin/env bash
# Golden tests for hamra-init: determinism + golden comparison.
#
# Renders every fixture in scripts/fixtures/*.json twice with the engine in
# --render-into mode (pure generation, no hardware probing, no writes outside
# a temp dir) and compares each tree byte-for-byte with
# scripts/fixtures/golden/<name>/.

set -u

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
ENGINE="$REPO/scripts/hamra-init.sh"
FIXTURES="$REPO/scripts/fixtures"
GOLDEN="$FIXTURES/golden"

failures=0
fixtures=$(find "$FIXTURES" -maxdepth 1 -name '*.json' -printf '%f\n' | sort)
[ -n "$fixtures" ] || { echo "no fixtures found"; exit 1; }

for fixture_name in $fixtures; do
    name="${fixture_name%.json}"
    fixture="$FIXTURES/$fixture_name"
    golden_dir="$GOLDEN/$name"

    first=$(mktemp -d)
    second=$(mktemp -d)
    bash "$ENGINE" --answers "$fixture" --render-into "$first" > /dev/null 2>&1
    bash "$ENGINE" --answers "$fixture" --render-into "$second" > /dev/null 2>&1

    if ! diff -r "$first" "$second" > /dev/null; then
        echo "FAIL $name: not deterministic"
        failures=$((failures + 1))
        continue
    fi

    if [ ! -d "$golden_dir" ]; then
        echo "FAIL $name: missing golden dir $golden_dir"
        failures=$((failures + 1))
        continue
    fi

    if ! diff -r "$first" "$golden_dir" > /dev/null; then
        echo "FAIL $name: output differs from golden"
        diff -r "$first" "$golden_dir" | head -10
        failures=$((failures + 1))
    else
        echo "PASS $name"
    fi

    rm -rf "$first" "$second"
done

exit $((failures > 0 ? 1 : 0))
