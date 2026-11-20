#!/usr/bin/env python3
"""Transpile each module on its own and run its ABAP Unit tests off-stack.

The modules are independent, so one module that cannot transpile must not hide
the results of the others. Each module therefore gets its own transpiler run and
its own line in the report.

This is a gate: the script exits 1 when a module is not fully green, unless
scripts/offstack_known_gaps.json names that module together with the reason.
A known gap is something the open-abap runtime does not implement yet - never
a defect of the ABAP. An entry allows exactly what it lists:

    "module": {
      "reason":  "what is missing off-stack, with the upstream pull request",
      "blocked": true,                      # the module may fail to transpile or crash
      "tests":   ["ltc_class->method"]      # the tests that may fail, nothing else
    }

An entry that is no longer needed is reported as a warning, so the list shrinks
again once the gap is closed upstream.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = ROOT / "src"
BASE_CONFIG = ROOT / "abap_transpile.json"
KNOWN_GAPS = ROOT / "scripts" / "offstack_known_gaps.json"
WORK_DIR = ROOT / ".transpile"
TRANSPILE_TIMEOUT = 300
RUN_TIMEOUT = 300

PASS, FAIL, RUNTIME, BLOCKED = "pass", "fail", "runtime", "blocked"

ICON = {PASS: "🟢", FAIL: "🟡", RUNTIME: "🟠", BLOCKED: "🔴"}
WORD = {
    PASS: "all green",
    FAIL: "tests failing",
    RUNTIME: "runtime error",
    BLOCKED: "cannot transpile",
}


def modules() -> list[str]:
    return sorted(p.name for p in SOURCE_DIR.iterdir() if p.is_dir())


def first_blocker(output: str) -> str:
    """The most useful line of a failed transpiler run."""
    interesting = []
    for line in output.splitlines():
        line = line.strip()
        if not line or line.startswith("at ") or line.startswith("Error: "):
            line = line.removeprefix("Error: ").strip()
        if line.startswith(("check_syntax,", "unknown_types,")):
            interesting.append(line)
    if not interesting:
        return "see the job log"
    head = interesting[0]
    extra = len(interesting) - 1
    return f"{head[:110]}{f'  (+{extra} more)' if extra else ''}"


def first_runtime_error(output: str) -> str:
    """Turn the raw crash dump into one readable line."""
    if "kernel_cx_assert" in output:
        actual = re.search(r"actual: \w+ \{ value: '([^']*)'", output)
        expected = re.search(r"expected: \w+ \{ value: '([^']*)'", output)
        if actual and expected:
            return f"assertion failed: expected `{expected.group(1)[:30]}`, got `{actual.group(1)[:30]}`"
        return "assertion failed"

    raised = re.search(r"<ref \*\d+> (\w+) \[Error\]", output)
    if raised:
        return f"uncaught {raised.group(1).lower()}"

    for line in output.splitlines():
        stripped = line.strip()
        if stripped.startswith(("TypeError", "ReferenceError", "RangeError", "SyntaxError")):
            return stripped[:110]

    return "see the job log"


def read_results(path: Path) -> list[dict]:
    """The runner writes failure messages without escaping them for JSON, so a
    message with a backslash (a regex, a path) makes the file invalid JSON. Such
    a lone backslash is read as a literal backslash instead of failing the report."""
    raw = path.read_text(encoding="utf-8")
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        payload = json.loads(re.sub(r'\\(.)', lambda m: m.group(0) if m.group(1) in '"\\/bfnrtu'
                                    else "\\\\" + m.group(1), raw, flags=re.S))
    return payload["list"] if isinstance(payload, dict) else payload


def run_module(name: str, base: dict) -> dict:
    out_dir = WORK_DIR / name
    shutil.rmtree(out_dir, ignore_errors=True)
    out_dir.mkdir(parents=True, exist_ok=True)

    config = dict(base)
    config["input_filter"] = [f"/{name}/"]
    config["exclude_filter"] = list(base.get("exclude_filter", [])) + ["_demo\\."]
    config["output_folder"] = str(out_dir.relative_to(ROOT))
    config_path = out_dir / "abap_transpile.json"
    config_path.write_text(json.dumps(config, indent=2), encoding="utf-8")

    started = time.time()
    build = subprocess.run(
        ["npx", "abap_transpile", str(config_path.relative_to(ROOT))],
        cwd=ROOT, capture_output=True, text=True, timeout=TRANSPILE_TIMEOUT,
    )
    if build.returncode != 0:
        return {"module": name, "status": BLOCKED, "total": 0, "failed": 0, "failures": [],
                "detail": first_blocker(build.stdout + build.stderr),
                "seconds": time.time() - started}

    # _unit_open.mjs is the generated ABAP Unit runner and the only entry point
    # that writes output.json; index.mjs runs the tests but reports nothing.
    entry = out_dir / "_unit_open.mjs"
    if not entry.exists():
        entry = out_dir / "index.mjs"
    if not entry.exists():
        return {"module": name, "status": BLOCKED, "total": 0, "failed": 0, "failures": [],
                "detail": "no unit tests generated", "seconds": time.time() - started}

    run = subprocess.run(
        ["node", str(entry)], cwd=ROOT, capture_output=True, text=True, timeout=RUN_TIMEOUT,
    )
    results_path = out_dir / "output.json"
    if not results_path.exists():
        started_count = (run.stdout + run.stderr).count("running ")
        return {"module": name, "status": RUNTIME, "total": started_count, "failed": 1, "failures": [],
                "detail": first_runtime_error(run.stdout + run.stderr),
                "seconds": time.time() - started}

    results = read_results(results_path)
    failed = [t for t in results if str(t.get("status", "")).upper() != "SUCCESS"]
    detail = ""
    if failed:
        first = failed[0]
        detail = f"{first['testclass_name'].lower()}->{first['method_name'].lower()}"
        if first.get("message"):
            detail += f": {str(first['message'])[:70]}"
        if len(failed) > 1:
            detail += f"  (+{len(failed) - 1} more)"
    return {"module": name, "status": FAIL if failed else PASS,
            "total": len(results), "failed": len(failed), "detail": detail,
            "failures": [test_name(t) for t in failed],
            "seconds": time.time() - started}


def test_name(test: dict) -> str:
    return f"{test['testclass_name'].lower()}->{test['method_name'].lower()}"


def known_gaps() -> dict:
    if not KNOWN_GAPS.exists():
        return {}
    return json.loads(KNOWN_GAPS.read_text(encoding="utf-8"))


def judge(row: dict, gap: dict | None) -> tuple[bool, str]:
    """Whether the module passes the gate, and what to say about a known gap.

    A module passes when it is fully green, or when everything that is not green
    is listed in its known gap. The text is empty unless there is something to say."""
    status = row["status"]
    if status == PASS:
        return True, "the known gap is closed - remove the entry" if gap else ""
    if gap is None:
        return False, ""
    if status in (BLOCKED, RUNTIME):
        return bool(gap.get("blocked")), ""
    unexpected = [name for name in row["failures"] if name not in gap.get("tests", [])]
    if unexpected:
        return False, f"not a known gap: {unexpected[0]}"
    return True, ""


def stale_parts(row: dict, gap: dict) -> list[str]:
    """What a known gap still lists although the module no longer needs it."""
    if row["status"] in (BLOCKED, RUNTIME):
        return []
    stale = [f"test {name} passes" for name in gap.get("tests", []) if name not in row["failures"]]
    if gap.get("blocked"):
        stale.insert(0, "the module transpiles and runs")
    return stale


def main() -> int:
    if not BASE_CONFIG.exists():
        print(f"::error::{BASE_CONFIG.name} not found")
        return 1

    base = json.loads(BASE_CONFIG.read_text(encoding="utf-8"))
    gaps = known_gaps()
    rows = []

    for name in modules():
        print(f"--- {name}", flush=True)
        try:
            row = run_module(name, base)
        except subprocess.TimeoutExpired:
            row = {"module": name, "status": RUNTIME, "total": 0, "failed": 1,
                   "detail": "timed out", "seconds": 0.0}
        rows.append(row)
        line = "    {0} {1}".format(ICON[row["status"]], WORD[row["status"]])
        if row["total"]:
            line += " — {0}/{1} tests".format(row["total"] - row["failed"], row["total"])
        if row["detail"]:
            line += " — " + row["detail"]
        print(line, flush=True)

    green = sum(1 for r in rows if r["status"] == PASS)
    passed = sum(r["total"] - r["failed"] for r in rows)
    total = sum(r["total"] for r in rows)

    rejected = []
    for row in rows:
        gap = gaps.get(row["module"])
        accepted, remark = judge(row, gap)
        if not accepted:
            rejected.append(row["module"])
            print(f"::error::Off-stack ABAP Unit: {row['module']} - {WORD[row['status']]}"
                  f"{' - ' + (remark or row['detail']) if (remark or row['detail']) else ''}")
        elif gap is not None:
            stale = [remark] if remark else stale_parts(row, gap)
            if stale:
                print(f"::warning::scripts/{KNOWN_GAPS.name}: {row['module']} - {'; '.join(stale)}")
            if row["status"] != PASS:
                row["detail"] = f"known gap: {gap.get('reason', 'no reason given')}"
    for name in sorted(set(gaps) - {r["module"] for r in rows}):
        print(f"::warning::scripts/{KNOWN_GAPS.name}: there is no module {name}")

    lines = [
        "## Off-stack ABAP Unit",
        "",
        f"**{green}/{len(rows)} modules fully green**, {passed}/{total} tests passing.",
        "",
        ("**Gate passed.**" if not rejected
         else "**Gate failed:** " + ", ".join(f"`{name}`" for name in rejected) + "."),
        "",
        "| | Module | Status | Tests | Detail |",
        "| --- | --- | --- | --- | --- |",
    ]
    for row in sorted(rows, key=lambda r: ([PASS, FAIL, RUNTIME, BLOCKED].index(r["status"]), r["module"])):
        count = f"{row['total'] - row['failed']}/{row['total']}" if row["total"] else "—"
        lines.append(f"| {ICON[row['status']]} | `{row['module']}` | {WORD[row['status']]} "
                     f"| {count} | {row['detail']} |")
    lines += [
        "",
        "🟢 all tests pass &nbsp; 🟡 tests run but some fail &nbsp; "
        "🟠 transpiles but crashes at runtime &nbsp; 🔴 an API is missing from open-abap",
        "",
        "This job fails when a module is not fully green. The only exception is a gap of the "
        f"open-abap runtime that is listed with its reason in `scripts/{KNOWN_GAPS.name}`.",
    ]

    report = "\n".join(lines)
    print()
    print(report)

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as handle:
            handle.write(report + "\n")

    return 1 if rejected else 0


if __name__ == "__main__":
    sys.exit(main())
