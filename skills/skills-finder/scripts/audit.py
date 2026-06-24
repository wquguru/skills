#!/usr/bin/env python3
"""Security-gate a skill before adoption using the public skills.sh audit API.

Fetches multi-provider security audits for one or more skills and applies a
deterministic adopt/reject policy. The audit endpoint is PUBLIC (no token), so
this gate always works even when discovery endpoints require auth.

Usage:
    audit.py <skill> [<skill> ...] [--json]

A <skill> may be given in any of these forms (all normalize to the same path):
    owner/repo@skill
    owner/repo/skill
    github/owner/repo@skill
    https://skills.sh/owner/repo/skill
    https://skills.sh/github/owner/repo/skill

Verdicts (and process exit code = worst verdict across all inputs):
    ADOPT      0   every provider passed; no risk above NONE/SAFE
    REVIEW    10   no fails, but a warn or LOW/MEDIUM risk needs a human call
    REJECT    20   a provider failed, or risk is HIGH/CRITICAL
    UNVERIFIED 30  no audits exist yet (404) — not safe to auto-adopt
    ERROR      1   network/parse error
"""
import json
import sys
import urllib.error
import urllib.request

API = "https://skills.sh/api/v1/skills/audit/"

# Risk levels treated as clean / caution / blocking.
CLEAN_RISK = {"SAFE", "NONE", "", None}
BLOCK_RISK = {"HIGH", "CRITICAL"}

VERDICT_CODE = {"ADOPT": 0, "REVIEW": 10, "REJECT": 20, "UNVERIFIED": 30, "ERROR": 1}


def normalize(raw):
    """Turn any accepted skill reference into the audit path suffix owner/repo/skill."""
    s = raw.strip()
    for prefix in ("https://skills.sh/", "http://skills.sh/", "skills.sh/"):
        if s.startswith(prefix):
            s = s[len(prefix):]
    s = s.replace("@", "/")  # owner/repo@skill -> owner/repo/skill
    return "/".join(p for p in s.split("/") if p)


def fetch(path):
    req = urllib.request.Request(API + path, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)


def classify(audits):
    """Apply the gate policy to a list of provider audit objects."""
    statuses = {a.get("status", "").lower() for a in audits}
    risks = {(a.get("riskLevel") or "").upper() for a in audits}
    if "fail" in statuses or risks & BLOCK_RISK:
        return "REJECT"
    if "warn" in statuses or (risks - {r.upper() if r else r for r in CLEAN_RISK if r}):
        # any non-clean risk left (LOW/MEDIUM) or a warn -> needs a human
        leftover = {r for r in risks if r and r not in {"SAFE", "NONE"}}
        if "warn" in statuses or leftover:
            return "REVIEW"
    return "ADOPT"


def assess(raw):
    path = normalize(raw)
    try:
        data = fetch(path)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return {"input": raw, "path": path, "verdict": "UNVERIFIED",
                    "reason": "no audits exist yet (404)", "audits": []}
        return {"input": raw, "path": path, "verdict": "ERROR",
                "reason": f"HTTP {e.code}", "audits": []}
    except Exception as e:  # noqa: BLE001 - report any network/parse failure
        return {"input": raw, "path": path, "verdict": "ERROR",
                "reason": str(e), "audits": []}
    audits = data.get("audits", [])
    if not audits:
        return {"input": raw, "path": path, "verdict": "UNVERIFIED",
                "reason": "no audits returned", "audits": []}
    verdict = classify(audits)
    return {"input": raw, "path": path, "verdict": verdict,
            "audits": [{"provider": a.get("provider"), "status": a.get("status"),
                        "riskLevel": a.get("riskLevel"), "summary": a.get("summary")}
                       for a in audits]}


def print_human(res):
    icon = {"ADOPT": "✅", "REVIEW": "⚠️ ", "REJECT": "⛔", "UNVERIFIED": "❓", "ERROR": "✗"}
    print(f"{icon.get(res['verdict'], '?')} {res['verdict']}  {res['path']}")
    if res.get("reason"):
        print(f"     {res['reason']}")
    for a in res["audits"]:
        risk = a.get("riskLevel") or "-"
        print(f"     - {a['provider']:<22} {str(a['status']):<5} risk={risk}")
        if a.get("summary") and res["verdict"] in ("REJECT", "REVIEW"):
            print(f"       {a['summary']}")


def main(argv):
    args = [a for a in argv if a != "--json"]
    as_json = "--json" in argv
    if not args:
        print(__doc__)
        return 1
    results = [assess(a) for a in args]
    if as_json:
        print(json.dumps(results, indent=2))
    else:
        for r in results:
            print_human(r)
            print()
    worst = max(VERDICT_CODE[r["verdict"]] for r in results)
    return worst


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
