#!/usr/bin/env python3
"""Transpile each module on its own and run its ABAP Unit tests off-stack.

The modules are independent, so one module that cannot transpile must not hide
the results of the others. Each module therefore gets its own transpiler run and
its own line in the report.

This is a feedback tool, not a gate: it always exits 0. Read the summary table.
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
        return {"module": name, "status": BLOCKED, "total": 0, "failed": 0,
                "detail": first_blocker(build.stdout + build.stderr),
                "seconds": time.time() - started}

    entry = out_dir / "index.mjs"
    if not entry.exists():
        return {"module": name, "status": BLOCKED, "total": 0, "failed": 0,
                "detail": "no unit tests generated", "seconds": time.time() - started}

    run = subprocess.run(
        ["node", str(entry)], cwd=ROOT, capture_output=True, text=True, timeout=RUN_TIMEOUT,
    )
    results_path = out_dir / "output.json"
    if not results_path.exists():
        started_count = (run.stdout + run.stderr).count("running ")
        return {"module": name, "status": RUNTIME, "total": started_count, "failed": 1,
                "detail": first_runtime_error(run.stdout + run.stderr),
                "seconds": time.time() - started}

    results = json.loads(results_path.read_text(encoding="utf-8"))["list"]
    failed = [t for t in results if t.get("status") != "pass"]
    detail = ""
    if failed:
        first = failed[0]
        detail = f"{first['testclass_name'].lower()}->{first['method_name'].lower()}"
        if len(failed) > 1:
            detail += f"  (+{len(failed) - 1} more)"
    return {"module": name, "status": FAIL if failed else PASS,
            "total": len(results), "failed": len(failed), "detail": detail,
            "seconds": time.time() - started}


def main() -> int:
    if not BASE_CONFIG.exists():
        print(f"::error::{BASE_CONFIG.name} not found")
        return 0

    base = json.loads(BASE_CONFIG.read_text(encoding="utf-8"))
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

    lines = [
        "## Off-stack ABAP Unit",
        "",
        f"**{green}/{len(rows)} modules fully green**, {passed}/{total} tests passing.",
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
        "This job never fails the build. A red module means the open-abap runtime does not "
        "implement an API the module uses, not that the ABAP is wrong.",
    ]

    report = "\n".join(lines)
    print()
    print(report)

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as handle:
            handle.write(report + "\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
