# Skills sync — symlink local skills into Claude Code and Codex skill dirs

skills_dir   := justfile_directory() / "skills"
external_dir := justfile_directory() / "external"
home         := env_var('HOME')
claude_dir   := home / ".claude" / "skills"
codex_dir    := home / ".codex" / "skills"

# Show available recipes
default:
    @just --list

# Pull third-party skills declared in external.yml into ./external/ (git-ignored),
# recording resolved commit SHAs in external.lock. Run `just add` afterwards.
vendor:
    @scripts/vendor.sh

# Symlink every skill in ./skills into ~/.claude/skills and ~/.codex/skills
add:
    #!/usr/bin/env bash
    set -euo pipefail
    for dest in "{{claude_dir}}" "{{codex_dir}}"; do
        mkdir -p "$dest"
        for src in "{{skills_dir}}"/*/ "{{external_dir}}"/*/; do
            [ -d "$src" ] || continue
            src="${src%/}"
            name="$(basename "$src")"
            target="$dest/$name"
            if [ -L "$target" ]; then
                if [ "$(readlink "$target")" = "$src" ]; then
                    echo "  ok      $target"
                else
                    echo "  skip    $target -> $(readlink "$target") (foreign symlink)"
                fi
                continue
            fi
            if [ -e "$target" ]; then
                echo "  skip    $target (exists, not a symlink)"
                continue
            fi
            ln -s "$src" "$target"
            echo "  linked  $target -> $src"
        done
    done

# Remove only the symlinks that point back into this repo
remove:
    #!/usr/bin/env bash
    set -euo pipefail
    for dest in "{{claude_dir}}" "{{codex_dir}}"; do
        for src in "{{skills_dir}}"/*/ "{{external_dir}}"/*/; do
            [ -d "$src" ] || continue
            src="${src%/}"
            name="$(basename "$src")"
            target="$dest/$name"
            if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
                rm "$target"
                echo "  removed $target"
            fi
        done
    done

# Show install status for each skill in both destinations
status:
    #!/usr/bin/env bash
    set -euo pipefail
    for dest in "{{claude_dir}}" "{{codex_dir}}"; do
        echo "$dest:"
        for src in "{{skills_dir}}"/*/ "{{external_dir}}"/*/; do
            [ -d "$src" ] || continue
            src="${src%/}"
            name="$(basename "$src")"
            target="$dest/$name"
            if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
                echo "  linked  $name"
            elif [ -e "$target" ]; then
                echo "  other   $name"
            else
                echo "  missing $name"
            fi
        done
    done
