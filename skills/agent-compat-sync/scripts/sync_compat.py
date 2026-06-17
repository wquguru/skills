#!/usr/bin/env python3
"""Synchronize Claude/Codex repo instruction files and skill directories."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path


def lexists(path: Path) -> bool:
    return os.path.lexists(path)


def rel_target(source: Path, link_parent: Path) -> str:
    return os.path.relpath(source, link_parent)


def same_symlink(destination: Path, source: Path) -> bool:
    if not destination.is_symlink():
        return False
    try:
        return destination.resolve(strict=True) == source.resolve(strict=True)
    except FileNotFoundError:
        return False


def same_resolved_path(destination: Path, source: Path) -> bool:
    if not lexists(destination) or not lexists(source):
        return False
    try:
        return destination.resolve(strict=True) == source.resolve(strict=True)
    except FileNotFoundError:
        return False


class Sync:
    def __init__(self, repo: Path, dry_run: bool) -> None:
        self.repo = repo.resolve()
        self.dry_run = dry_run
        self.actions: list[str] = []
        self.conflicts: list[str] = []

    def log(self, message: str) -> None:
        self.actions.append(message)

    def conflict(self, message: str) -> None:
        self.conflicts.append(message)

    def create_symlink(self, source: Path, destination: Path) -> None:
        if same_symlink(destination, source):
            self.log(f"ok: {destination.relative_to(self.repo)} already points to {source.relative_to(self.repo)}")
            return

        if same_resolved_path(destination, source):
            self.log(
                f"ok: {destination.relative_to(self.repo)} already resolves to "
                f"{source.relative_to(self.repo)}"
            )
            return

        if lexists(destination):
            self.conflict(
                f"conflict: {destination.relative_to(self.repo)} exists and is not a symlink to "
                f"{source.relative_to(self.repo)}"
            )
            return

        target = rel_target(source, destination.parent)
        self.log(f"link: {destination.relative_to(self.repo)} -> {target}")
        if not self.dry_run:
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.symlink_to(target)

    def canonical_from_docs(self) -> str | None:
        claude = self.repo / "CLAUDE.md"
        agents = self.repo / "AGENTS.md"
        has_claude = lexists(claude)
        has_agents = lexists(agents)

        if has_claude and not has_agents:
            return "claude"
        if has_agents and not has_claude:
            return "agents"
        if not has_claude and not has_agents:
            self.conflict("conflict: neither CLAUDE.md nor AGENTS.md exists")
            return None

        if agents.is_symlink() and same_symlink(agents, claude):
            return "claude"
        if claude.is_symlink() and same_symlink(claude, agents):
            return "agents"

        self.conflict("conflict: both CLAUDE.md and AGENTS.md exist independently; choose a canonical file first")
        return None

    def sync_docs(self, canonical: str) -> None:
        if canonical == "claude":
            self.create_symlink(self.repo / "CLAUDE.md", self.repo / "AGENTS.md")
        else:
            self.create_symlink(self.repo / "AGENTS.md", self.repo / "CLAUDE.md")

    def sync_skills(self, canonical: str) -> None:
        if canonical == "claude":
            source_dir = self.repo / ".claude" / "skills"
            destination_dir = self.repo / ".agents" / "skills"
        else:
            source_dir = self.repo / ".agents" / "skills"
            destination_dir = self.repo / ".claude" / "skills"

        if not source_dir.exists():
            self.log(f"skip: {source_dir.relative_to(self.repo)} does not exist")
            return
        if not source_dir.is_dir():
            self.conflict(f"conflict: {source_dir.relative_to(self.repo)} exists but is not a directory")
            return

        for source in sorted(source_dir.iterdir(), key=lambda p: p.name):
            self.create_symlink(source, destination_dir / source.name)

    def run(self) -> int:
        canonical = self.canonical_from_docs()
        if canonical:
            self.log(f"canonical: {canonical}")
            self.sync_docs(canonical)
            self.sync_skills(canonical)

        for action in self.actions:
            print(action)

        if self.conflicts:
            for conflict in self.conflicts:
                print(conflict, file=sys.stderr)
            return 1
        return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=".", help="Repository root to synchronize. Defaults to current directory.")
    parser.add_argument("--dry-run", action="store_true", help="Print planned changes without writing files.")
    args = parser.parse_args()

    repo = Path(args.repo)
    if not repo.exists() or not repo.is_dir():
        print(f"error: repo path is not a directory: {repo}", file=sys.stderr)
        return 2

    return Sync(repo, args.dry_run).run()


if __name__ == "__main__":
    raise SystemExit(main())
