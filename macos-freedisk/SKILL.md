---
name: macos-freedisk
description: Safely audit and reclaim disk space on macOS. Use when the user says their Mac disk is full, asks what can be safely deleted, wants to clean caches, developer artifacts, Docker Desktop storage, Homebrew/npm/pnpm/yarn caches, Xcode data, editor extensions, node_modules, logs, Trash, or asks for a repeatable macOS free-space cleanup workflow.
---

# macOS Free Disk

## Core Rule

Prefer a read-only audit before deleting anything. Classify findings into safety tiers, explain likely impact, and only delete after the user clearly asks to clean. Never delete personal documents, project archives, photos, mail, source repositories, Docker volumes, or app containers unless the user explicitly names them.

## Quick Audit

Run the bundled read-only script first when possible:

```bash
bash scripts/audit_macos_disk.sh
```

Use `PROJECT_SCAN=1 bash scripts/audit_macos_disk.sh` to include common project roots such as `~/Workshop` and `~/qb`. Use `FULL_SCAN=1 bash scripts/audit_macos_disk.sh` only when the user wants a deeper scan and the disk has enough free space for a slower traversal.

If the script is not suitable, gather the same facts manually:

```bash
df -h /
du -sh ~/Library/Caches ~/.npm ~/.pnpm-store ~/.yarn ~/.cache ~/Library/Logs ~/.Trash 2>/dev/null
du -sh ~/Library/Containers/com.docker.docker ~/Library/Developer ~/Downloads 2>/dev/null
find ~ -xdev -type f -size +1G -print 2>/dev/null | head -100
```

Use `du -hd 1 <dir> | sort -h | tail` for large directories. Prefer targeted scans over full-home scans when the disk is very full.

## Safety Tiers

Treat these as usually safe to clean:

- Homebrew old versions and cache: `brew cleanup`, then optionally remove `~/Library/Caches/Homebrew/*`.
- Package manager caches: `npm cache clean --force`, `pnpm store prune`, `yarn cache clean`.
- Reinstallable dependencies the user names: `node_modules`, `.venv`, build outputs, `.next`, `dist`, `target`.
- User logs: files under `~/Library/Logs`.
- Trash: `~/.Trash`, only after confirming nothing important is there.

Treat these as safe but with workflow impact:

- VS Code/Cursor extensions under `~/.vscode/extensions` and `~/.cursor/extensions`; deleting them uninstalls extensions.
- Xcode DerivedData and simulator caches; deleting them slows the next build or simulator boot.
- Python/uv/pip caches and tool environments; deleting them may require reinstalling tools.
- Agent or editor histories such as `.claude/projects`, `.codex/sessions`, `.cursor/projects`; deleting them may remove local history.

Treat these as high impact:

- Docker Desktop `Docker.raw`: never delete directly. Use Docker prune commands and Docker Desktop compaction/reset behavior.
- Docker volumes: do not run `docker volume prune` unless the user explicitly accepts losing persistent container data.
- `~/Downloads`, project archives, media, iCloud Drive, Mail, Photos libraries, and app containers: report size and ask.
- APFS local snapshots: report them, but avoid deleting snapshots unless the user explicitly asks and understands the backup/update implications.

## Cleanup Workflow

1. State current free space from `df -h /`.
2. Report candidates by tier with sizes and impact.
3. Clean low-risk caches first when asked:

```bash
brew cleanup
npm cache clean --force
pnpm store prune
yarn cache clean
```

4. Remove user-named reinstallable directories with `rm -rf` only after repeating the exact paths.
5. For Docker, start Docker Desktop if needed, then run:

```bash
docker system prune -af
docker builder prune -af
docker system df
```

Skip `docker volume prune -f` unless the user explicitly requests volume deletion.

6. Recheck:

```bash
df -h /
docker system df 2>/dev/null || true
```

Summarize what was cleaned, what was intentionally skipped, the new free-space number, and any follow-up impact such as reinstalling editor extensions or dependencies.
