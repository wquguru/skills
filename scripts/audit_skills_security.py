#!/usr/bin/env python3
"""Static security audit for Agent Skills.

Scans skill sources (SKILL.md, scripts, references) for supply-chain and
credential risks that matter when an agent may *execute* a skill's contents:
remote-code execution, reverse shells, destructive commands, hardcoded secrets,
credential exfiltration, and insecure transport.

Dependency-free (stdlib only) so it runs identically in CI and on a laptop.

Usage:
    audit_skills_security.py [PATH ...] [--format text|json]
                             [--fail-on critical|high|medium|low|none]
                             [--min-severity critical|high|medium|low]

PATH defaults to `skills/`. Exit code is 0 when no finding meets --fail-on
(default: critical), else 1. A parse/usage error exits 2.

Suppress a single false positive by adding an inline marker on the offending
line (or the line above it):

    something risky here   # skills-audit: allow remote-exec-pipe
    # skills-audit: allow-all
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, asdict
from pathlib import Path

SEVERITIES = ["critical", "high", "medium", "low"]
SUPPRESS_RE = re.compile(r"skills-audit:\s*allow(?:-(all)|\s+([a-z0-9-]+))")

# Values that look like documentation placeholders rather than real credentials.
PLACEHOLDER_RE = re.compile(
    r"[<>${}]|\.\.\.|(?i:example|changeme|your[_-]?|xxx+|placeholder|redacted|"
    r"var[_-]?name|token[_-]?here|dummy|fake|sample|<.*?>)")

# Only scan human-readable skill sources; skip vendored, binary, and asset files.
TEXT_SUFFIXES = {".md", ".sh", ".bash", ".zsh", ".py", ".yml", ".yaml",
                 ".txt", ".json", ".toml", ".cfg", ".env", ".ps1", ".rb", ".js", ".ts"}
SKIP_DIRS = {".git", "external", "node_modules", "assets", ".idea", "__pycache__"}


@dataclass(frozen=True)
class Rule:
    id: str
    severity: str
    pattern: re.Pattern
    message: str
    redact: bool = False  # redact the matched text in output (secrets)


def r(id, severity, regex, message, *, flags=0, redact=False) -> Rule:
    return Rule(id, severity, re.compile(regex, flags), message, redact)


# Ordered roughly by severity. Kept intentionally conservative to avoid noise:
# the default gate only fails on `critical`, so `high`/`medium`/`low` are advisory.
RULES: list[Rule] = [
    # ---- critical: arbitrary / remote code execution ------------------------
    r("remote-exec-pipe", "critical",
      r"(?:curl|wget|fetch)\b[^\n|]*\|\s*(?:sudo\s+)?(?:(?:bash|sh|zsh)\b|(?:python3?|ruby|perl|node)\b(?!\s+-[mc]\b))",
      "Piping a downloaded payload straight into an interpreter (curl … | sh)."),
    r("eval-remote", "critical",
      r"\beval\b[^\n]*\$\((?:curl|wget|fetch)\b",
      "eval of remotely fetched content."),
    r("base64-exec", "critical",
      r"base64\s+(?:--decode|-d|-D)\b[^\n|]*\|\s*(?:bash|sh|zsh|python3?|node)\b",
      "Decoding base64 and piping into a shell — classic obfuscated payload."),
    r("reverse-shell", "critical",
      r"/dev/tcp/|\bnc\b[^\n]*\s-e\b|\bbash\b\s+-i\b[^\n]*>&|mkfifo[^\n]*\|\s*nc\b",
      "Reverse-shell primitive."),
    r("rm-root", "critical",
      r"\brm\s+-[rRfv]*[rf][rRfv]*\s+(?:--no-preserve-root\s+)?['\"]?(?:/|~|\$\{?HOME\}?)/?\*?(?:['\"\s;&|]|$)",
      "Destructive recursive delete of a root/home path."),
    r("curl-to-file-exec", "critical",
      r"(?:curl|wget)\b[^\n]*\s-o\s*\S+[^\n]*&&[^\n]*(?:bash|sh|chmod\s+\+x)",
      "Download-then-execute chain."),
    # ---- critical: credential exfiltration ---------------------------------
    r("cred-exfil", "critical",
      r"(?:curl|wget|nc)\b[^\n]*(?:\$AWS_SECRET\w*|\$AWS_ACCESS\w*|\$GITHUB_TOKEN|\$NPM_TOKEN|~/\.aws/credentials|~/\.ssh/id_|/etc/(?:passwd|shadow))",
      "Sending credentials or secret files over the network."),
    r("env-exfil", "critical",
      r"\benv\b\s*\|\s*(?:curl|wget|nc)\b|printenv[^\n]*\|\s*(?:curl|wget|nc)\b",
      "Piping the environment (which may hold secrets) to the network."),
    # ---- critical: hardcoded secrets ---------------------------------------
    r("private-key", "critical",
      r"-----BEGIN (?:RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----",
      "Committed private key.", redact=True),
    r("aws-access-key", "critical",
      r"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b",
      "Hardcoded AWS access key id.", redact=True),
    r("github-token", "critical",
      r"\bgh[pousr]_[A-Za-z0-9]{20,}\b|\bgithub_pat_[A-Za-z0-9_]{20,}\b",
      "Hardcoded GitHub token.", redact=True),
    r("slack-token", "critical",
      r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b",
      "Hardcoded Slack token.", redact=True),
    r("google-api-key", "critical",
      r"\bAIza[0-9A-Za-z\-_]{35}\b",
      "Hardcoded Google API key.", redact=True),
    # ---- high: insecure transport / permissions ----------------------------
    r("tls-verify-off", "high",
      r"curl\b[^\n]*\s-k\b|--no-check-certificate|insecureSkipVerify\s*[:=]\s*true|NODE_TLS_REJECT_UNAUTHORIZED\s*=\s*['\"]?0",
      "TLS certificate verification disabled."),
    r("insecure-download", "high",
      r"(?:curl|wget)\b[^\n]*\shttp://(?!localhost|127\.0\.0\.1|\[::1\]|0\.0\.0\.0)\S+",
      "Fetching over plaintext http:// (tamperable in transit)."),
    r("chmod-world-write", "high",
      r"\bchmod\s+(?:-[A-Za-z]+\s+)?0?777\b",
      "chmod 777 grants world write."),
    r("secret-assignment", "high",
      r"(?i)\b(?:api[_-]?key|secret|token|password|passwd|access[_-]?key)\b\s*[:=]\s*['\"][^'\"\s]{8,}['\"]",
      "Possible hardcoded credential in an assignment.", redact=True),
    # ---- medium: persistence / anti-forensics ------------------------------
    r("shell-persistence", "medium",
      r">>\s*~?/?(?:\$HOME/)?\.(?:bashrc|zshrc|profile|bash_profile|zprofile)\b",
      "Writing to a shell startup file (persistence)."),
    r("crontab-write", "medium",
      r"\bcrontab\s+(?:-|-e\b|-r\b)",
      "Modifying crontab (persistence / scheduled execution)."),
    r("history-tamper", "medium",
      r"\bunset\s+HISTFILE\b|HISTFILE=/dev/null|\bhistory\s+-c\b",
      "Disabling or clearing shell history (anti-forensics)."),
    r("prompt-injection", "medium",
      r"(?i)ignore (?:all )?previous instructions|disregard (?:the )?(?:above|system) (?:prompt|instructions)|exfiltrat",
      "Prompt-injection / instruction-override phrasing in skill text."),
    # ---- low: informational ------------------------------------------------
    r("sudo-usage", "low",
      r"(?<!no)\bsudo\b",
      "Uses sudo — confirm elevated privileges are warranted."),
]

RANK = {s: i for i, s in enumerate(SEVERITIES)}


@dataclass
class Finding:
    severity: str
    rule: str
    file: str
    line: int
    message: str
    excerpt: str


def iter_files(root: Path):
    if root.is_file():
        yield root
        return
    for p in sorted(root.rglob("*")):
        if not p.is_file():
            continue
        if any(part in SKIP_DIRS for part in p.parts):
            continue
        if p.suffix.lower() in TEXT_SUFFIXES:
            yield p


def suppressions(line: str) -> tuple[bool, set[str]]:
    """Return (allow_all, {rule ids}) suppressed by markers on this line."""
    allow_all = False
    ids: set[str] = set()
    for m in SUPPRESS_RE.finditer(line):
        if m.group(1):  # allow-all
            allow_all = True
        elif m.group(2):
            ids.add(m.group(2))
    return allow_all, ids


def scan_file(path: Path) -> list[Finding]:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []
    lines = text.splitlines()
    findings: list[Finding] = []
    for i, line in enumerate(lines, 1):
        prev = lines[i - 2] if i >= 2 else ""
        allow_all, allow_ids = suppressions(line)
        pa, pids = suppressions(prev)
        allow_all = allow_all or pa
        allow_ids |= pids
        if allow_all:
            continue
        for rule in RULES:
            if rule.id in allow_ids:
                continue
            m = rule.pattern.search(line)
            if not m:
                continue
            # Skip obvious documentation placeholders for the generic secret rule.
            if rule.id == "secret-assignment" and PLACEHOLDER_RE.search(m.group(0)):
                continue
            excerpt = line.strip()
            if rule.redact:
                excerpt = excerpt.replace(m.group(0), "«redacted»")
            excerpt = excerpt[:200]
            rel = os.path.relpath(path, Path.cwd())
            findings.append(Finding(rule.severity, rule.id, rel, i, rule.message, excerpt))
    return findings


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Static security audit for Agent Skills.")
    ap.add_argument("paths", nargs="*", default=["skills"],
                    help="files or dirs to scan (default: skills)")
    ap.add_argument("--format", choices=["text", "json"], default="text")
    ap.add_argument("--fail-on", choices=SEVERITIES + ["none"], default="critical",
                    help="lowest severity that fails the run (default: critical)")
    ap.add_argument("--min-severity", choices=SEVERITIES, default="low",
                    help="lowest severity to report (default: low)")
    args = ap.parse_args(argv)

    roots = [Path(p) for p in (args.paths or ["skills"])]
    missing = [str(p) for p in roots if not p.exists()]
    if missing:
        print(f"error: path(s) not found: {', '.join(missing)}", file=sys.stderr)
        return 2

    findings: list[Finding] = []
    for root in roots:
        for f in iter_files(root):
            findings.extend(scan_file(f))

    min_rank = RANK[args.min_severity]
    shown = [f for f in findings if RANK[f.severity] <= min_rank]
    shown.sort(key=lambda f: (RANK[f.severity], f.file, f.line))

    counts = {s: sum(1 for f in findings if f.severity == s) for s in SEVERITIES}

    if args.format == "json":
        print(json.dumps({
            "summary": counts,
            "findings": [asdict(f) for f in shown],
        }, indent=2))
    else:
        if not shown:
            print("✓ skills security audit: no findings")
        for f in shown:
            print(f"[{f.severity.upper():8}] {f.rule}: {f.file}:{f.line}")
            print(f"           {f.message}")
            print(f"           > {f.excerpt}")
        total = " ".join(f"{counts[s]} {s}" for s in SEVERITIES)
        print(f"\nsummary: {total}")

    if args.fail_on == "none":
        return 0
    gate = RANK[args.fail_on]
    if any(RANK[f.severity] <= gate for f in findings):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
