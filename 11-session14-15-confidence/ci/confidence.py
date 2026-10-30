#!/usr/bin/env python3
"""Measurable confidence - the scorecard the pipeline decides on.

Reads the thresholds from your test strategy (specs/design/test-strategy.md, table "Confidence
thresholds"), measures each signal from the reports the pipeline produced, and writes confidence.md and
confidence.json. Exit code 1 if any signal due at this point is missed - or cannot be measured.

    python3 ci/confidence.py --when merge          # before merge: tests, coverage, API checks on the app
    python3 ci/confidence.py --when deploy         # after deploy: everything, against the test environment
    python3 ci/confidence.py --env                 # print thresholds as KEY=value (for k6 and friends)

Standard library only. Rows in the strategy look like:
    | CS-003 | Coverage, lines | coverage.line | >= 72 | QG-007 ratchet | merge |
A check you have designed but not built yet gets a planned measure - shown, never counted as met:
    | CS-009 | No high-risk findings from DAST | planned.dast | = 0 | NFR-005 | deploy |
"""

import argparse
import glob
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

MEASURES = {
    "tests.pass_rate": "unit, integration and scenario tests that passed, %",
    "tests.count": "unit, integration and scenario tests that ran",
    "coverage.line": "line coverage, %",
    "api.pass_rate": "API checks (Postman) that passed, %",
    "e2e.pass_rate": "end-to-end journeys that passed, %",
    "perf.p95_ms": "95th percentile response time, ms",
    "perf.error_rate": "failed requests under load, %",
    "smoke.version": "the deployed service answers, with this commit (1 = yes)",
}
ROW = re.compile(
    r"^\|\s*(CS-\d{3})\s*\|([^|]*)\|\s*([a-z0-9_.]+)\s*\|([^|]*)\|([^|]*)\|\s*(merge|deploy)\s*\|",
    re.MULTILINE,
)
THRESHOLD = re.compile(r"^\s*(>=|<=|=|<|>)\s*([0-9.]+)")


def junit(patterns: list[str]) -> tuple[int, int] | None:
    total = failed = 0
    found = False
    for pat in patterns:
        for f in glob.glob(pat, recursive=True):
            found = True
            for case in ET.parse(f).getroot().iter("testcase"):
                if case.find("skipped") is not None:
                    continue
                total += 1
                if case.find("failure") is not None or case.find("error") is not None:
                    failed += 1
    return (total, failed) if found else None


def coverage(patterns: list[str]) -> float | None:
    for pat in patterns:
        for f in glob.glob(pat, recursive=True):
            root = ET.parse(f).getroot()
            if root.get("line-rate") is not None:  # cobertura
                return round(float(root.get("line-rate")) * 100, 1)
            for c in root.findall("counter"):  # jacoco, report level
                if c.get("type") == "LINE":
                    covered, missed = int(c.get("covered")), int(c.get("missed"))
                    return round(100 * covered / max(covered + missed, 1), 1)
    return None


def k6(path: str) -> dict | None:
    if not Path(path).exists():
        return None
    m = json.loads(Path(path).read_text())["metrics"]
    return {
        "p95": m.get("http_req_duration", {}).get("p(95)"),
        "fail": m.get("http_req_failed", {}).get("value"),
    }


def pct(result: tuple[int, int] | None) -> float | None:
    return (
        None
        if result is None or result[0] == 0
        else round(100 * (result[0] - result[1]) / result[0], 1)
    )


def measure(a: argparse.Namespace) -> dict:
    t = junit(a.tests)
    api, e2e, perf = junit(a.api), junit(a.e2e), k6(a.perf)
    health = json.loads(Path(a.health).read_text()) if Path(a.health).exists() else None
    return {
        "tests.pass_rate": pct(t),
        "tests.count": None if t is None else t[0],
        "coverage.line": coverage(a.coverage),
        "api.pass_rate": pct(api),
        "e2e.pass_rate": pct(e2e),
        "perf.p95_ms": None
        if perf is None or perf["p95"] is None
        else round(perf["p95"], 1),
        "perf.error_rate": None
        if perf is None or perf["fail"] is None
        else round(100 * perf["fail"], 2),
        "smoke.version": None
        if health is None
        else int(bool(health.get("ok")) and health.get("version") == a.commit),
    }


def met(value: float, op: str, limit: float) -> bool:
    return {
        ">=": value >= limit,
        "<=": value <= limit,
        "=": value == limit,
        "<": value < limit,
        ">": value > limit,
    }[op]


def rows(strategy: Path) -> list[dict]:
    if not strategy.exists():
        sys.exit(
            f"No {strategy} - write it first: /test-strategy (template: templates/test-strategy.md)"
        )
    out = []
    for m in ROW.finditer(strategy.read_text(encoding="utf-8")):
        cid, signal, key, threshold, source, when = (x.strip() for x in m.groups())
        if key not in MEASURES and not key.startswith("planned."):
            sys.exit(
                f"{cid}: unknown measure '{key}'. Measures: {', '.join(MEASURES)} - "
                "or planned.<name> for a check that is not built yet"
            )
        t = THRESHOLD.match(
            threshold
        )  # "<today's count>" and friends: not set yet - and not confidence
        out.append(
            {
                "id": cid,
                "signal": signal,
                "measure": key,
                "op": t.group(1) if t else None,
                "limit": float(t.group(2)) if t else None,
                "threshold": threshold,
                "source": source,
                "when": when,
            }
        )
    if not out:
        sys.exit(
            f"{strategy} has no 'Confidence thresholds' rows (| CS-001 | ... | merge |) - fill the table first"
        )
    return out


def main() -> int:
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("--when", choices=["merge", "deploy"], default="merge")
    p.add_argument("--strategy", default="specs/design/test-strategy.md")
    p.add_argument(
        "--tests",
        nargs="*",
        default=[
            "report.xml",
            "scenarios.xml",
            "**/junit*.xml",
            "**/target/surefire-reports/TEST-*.xml",
        ],
    )
    p.add_argument(
        "--coverage",
        nargs="*",
        default=[
            "coverage.xml",
            "**/cobertura-coverage.xml",
            "**/target/site/jacoco/jacoco.xml",
        ],
    )
    p.add_argument("--api", nargs="*", default=["newman*.xml"])
    p.add_argument("--e2e", nargs="*", default=["**/e2e.xml"])
    p.add_argument("--perf", default="k6-summary.json")
    p.add_argument("--health", default="health.json")
    p.add_argument("--commit", default=os.getenv("CI_COMMIT_SHORT_SHA", "local"))
    p.add_argument(
        "--env", action="store_true", help="print the thresholds as KEY=value and stop"
    )
    a = p.parse_args()

    spec = rows(Path(a.strategy))
    if a.env:
        names = {
            "perf.p95_ms": "P95_MS",
            "perf.error_rate": "ERROR_RATE",
            "coverage.line": "COVERAGE_MIN",
        }
        for r in spec:
            if r["measure"] in names and r["op"]:
                v = (
                    r["limit"] / 100
                    if r["measure"] == "perf.error_rate"
                    else r["limit"]
                )
                print(f"{names[r['measure']]}={v:g}")
        return 0

    got = measure(a)
    results, missed = [], 0
    for r in spec:
        due = r["when"] == "merge" or a.when == "deploy"
        value = got.get(r["measure"])
        if r["measure"].startswith("planned."):
            state = "planned"
        elif not due:
            state = "later"
        elif r["op"] is None:
            state, missed = "NOT SET", missed + 1
        elif value is None:
            state, missed = "NOT MEASURED", missed + 1
        elif met(value, r["op"], r["limit"]):
            state = "met"
        else:
            state, missed = "MISSED", missed + 1
        results.append({**r, "value": value, "state": state})

    due_rows = [r for r in results if r["state"] not in ("later", "planned")]
    planned = sum(r["state"] == "planned" for r in results)
    ok = len(due_rows) - missed
    verdict = "CONFIDENT" if missed == 0 else "NOT CONFIDENT"
    lines = [
        f"# Confidence - {verdict}",
        "",
        f"*{a.when} · commit {a.commit} · {ok} of {len(due_rows)} signals met"
        + (f" · {planned} planned, not built yet" if planned else "")
        + f" · thresholds from {a.strategy}*",
        "",
        "| ID | Signal | Measured | Threshold | Source | Result |",
        "|---|---|---|---|---|---|",
    ]
    for r in results:
        v = "-" if r["value"] is None else f"{r['value']:g}"
        mark = {
            "met": "met",
            "MISSED": "**MISSED**",
            "NOT MEASURED": "**NOT MEASURED**",
            "NOT SET": "**NOT SET**",
            "later": "after deploy",
            "planned": "planned - not built yet",
        }[r["state"]]
        lines.append(
            f"| {r['id']} | {r['signal']} | {v} | {r['threshold']} | {r['source']} | {mark} |"
        )
    lines += [
        "",
        "A signal that could not be measured - or a threshold nobody set - is not confidence.",
    ]
    Path("confidence.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    Path("confidence.json").write_text(
        json.dumps(
            {
                "verdict": verdict,
                "when": a.when,
                "commit": a.commit,
                "met": ok,
                "due": len(due_rows),
                "planned": planned,
                "signals": results,
            },
            indent=2,
        )
    )
    print("\n".join(lines))
    return 0 if missed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
