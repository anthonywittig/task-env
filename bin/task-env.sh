#!/usr/bin/env bash
# task-env.sh — scaffold a dated task workspace and clone one or more repos into it.
#
# Usage:
#   task-env.sh <profile> <mode> <task-name> <repo> [repo...]
#
# Arguments:
#   profile    Workspace profile (e.g. work, personal)
#   mode       cursor | claude — which tool to open after cloning
#   task-name  Short task label (spaces become hyphens in the path)
#   repo       Clone target: git URL, or GitHub owner/repo shorthand.
#              HTTP(S) URLs are rewritten to SSH.
#              Pass more than one, separated by spaces.
#
# Creates:
#   ~/code/tasks/{profile}/{yyyy-mm-dd}--{task-name}--{mode}/
# One repo is cloned as that directory. Multiple repos are cloned as
# subdirectories under it (named from each repo), then the workspace opens:
#   cursor  → cursor .
#   claude  → claude --dangerously-skip-permissions

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: task-env.sh <profile> <mode> <task-name> <repo> [repo...]

  profile    Workspace profile (e.g. work, personal)
  mode       cursor | claude
  task-name  Short task label (spaces become hyphens)
  repo       Git URL, or GitHub owner/repo shorthand.
             HTTP(S) URLs are cloned over SSH.
             Repeat for more than one repo, separated by spaces.

One repo is cloned as the workspace directory. Multiple repos are cloned
as subdirectories under it.

After cloning, opens the workspace:
  cursor  → cursor .
  claude  → claude --dangerously-skip-permissions

Examples:
  task-env.sh work cursor "fix login" owner/repo
  → ~/code/tasks/work/2026-07-31--fix-login--cursor/

  task-env.sh work cursor "fix login" owner/api owner/web
  → ~/code/tasks/work/2026-07-31--fix-login--cursor/api
  → ~/code/tasks/work/2026-07-31--fix-login--cursor/web
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

slugify() {
  # Lowercase, spaces/underscores → hyphens, strip unsafe path chars, collapse hyphens.
  local s
  s=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr ' _' '-')
  s=$(printf '%s' "$s" | tr -cd 'a-z0-9.-')
  s=$(printf '%s' "$s" | sed -E 's/-+/-/g; s/^-+//; s/-+$//')
  printf '%s' "$s"
}

# Rewrite an http(s) clone URL to SSH. A port stays in ssh:// form because
# git@host:path uses the colon as the path separator.
https_to_ssh() {
  local url=$1
  local rest host path
  case "$url" in
    https://*) rest=${url#https://} ;;
    http://*) rest=${url#http://} ;;
    *) die "not an http(s) URL: $url" ;;
  esac
  # Drop userinfo (https://user:token@host/path).
  case "$rest" in
    *@*) rest=${rest#*@} ;;
  esac
  case "$rest" in
    */*) ;;
    *) die "could not convert $url to an SSH URL" ;;
  esac
  host=${rest%%/*}
  path=${rest#*/}
  path=${path%%\?*}
  path=${path%%#*}
  path=${path%/}
  [[ -n "$host" && -n "$path" ]] || die "could not convert $url to an SSH URL"
  case "$host" in
    *:*)
      printf 'ssh://git@%s/%s' "$host" "$path"
      ;;
    *)
      printf 'git@%s:%s' "$host" "$path"
      ;;
  esac
}

resolve_repo_url() {
  local repo=$1
  case "$repo" in
    git@*|ssh://*|file://*)
      printf '%s' "$repo"
      ;;
    https://*|http://*)
      https_to_ssh "$repo"
      ;;
    */*)
      # GitHub shorthand: owner/repo[.git]
      local path=${repo%.git}
      printf 'git@github.com:%s.git' "$path"
      ;;
    *)
      die "repo must be a git URL or GitHub owner/repo (got: $repo)"
      ;;
  esac
}

# Directory name git would use: last path segment, without a trailing .git.
repo_dirname() {
  local url=$1
  local name
  name=${url%/}
  name=${name##*/}
  name=${name%.git}
  name=${name##*:}
  case "$name" in
    ''|.|..|*/*)
      die "could not derive a directory name from $url"
      ;;
  esac
  printf '%s' "$name"
}

open_workspace() {
  local mode=$1
  local target_dir=$2

  cd "$target_dir"
  case "$mode" in
    cursor)
      command -v cursor >/dev/null 2>&1 || die "cursor CLI not found in PATH"
      echo "Opening with Cursor…"
      cursor .
      ;;
    claude)
      command -v claude >/dev/null 2>&1 || die "claude CLI not found in PATH"
      echo "Opening with Claude…"
      claude --dangerously-skip-permissions
      ;;
    *)
      die "mode must be 'cursor' or 'claude' (got: $mode)"
      ;;
  esac
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 4 ]]; then
  usage >&2
  exit 1
fi

profile_raw=$1
mode_raw=$2
task_raw=$3
shift 3
repos=("$@")

profile=$(slugify "$profile_raw")
mode=$(slugify "$mode_raw")
task=$(slugify "$task_raw")

[[ -n "$profile" ]] || die "profile is empty after sanitizing"
[[ -n "$mode" ]] || die "mode is empty after sanitizing"
[[ -n "$task" ]] || die "task-name is empty after sanitizing"

case "$mode" in
  cursor|claude) ;;
  *) die "mode must be 'cursor' or 'claude' (got: $mode_raw)" ;;
esac

for repo in "${repos[@]}"; do
  [[ -n "$repo" ]] || die "repo is required"
done

repo_urls=()
for repo in "${repos[@]}"; do
  repo_urls+=("$(resolve_repo_url "$repo")")
done

repo_dirs=()
if [[ ${#repo_urls[@]} -gt 1 ]]; then
  seen=$'\n'
  for url in "${repo_urls[@]}"; do
    name=$(repo_dirname "$url")
    case "$seen" in
      *$'\n'"$name"$'\n'*)
        die "multiple repos would clone into '$name'; use distinct repository names"
        ;;
    esac
    seen+=$name$'\n'
    repo_dirs+=("$name")
  done
fi

today=$(date +%Y-%m-%d)
dir_name="${today}--${task}--${mode}"
target_dir="${HOME}/code/tasks/${profile}/${dir_name}"

if [[ -e "$target_dir" ]]; then
  die "target already exists: $target_dir"
fi

mkdir -p "$target_dir"
echo "Created $target_dir"

if [[ ${#repo_urls[@]} -eq 1 ]]; then
  echo "Cloning ${repo_urls[0]} → $target_dir"
  git clone "${repo_urls[0]}" "$target_dir"
else
  for i in "${!repo_urls[@]}"; do
    dest="${target_dir}/${repo_dirs[$i]}"
    echo "Cloning ${repo_urls[$i]} → $dest"
    git clone "${repo_urls[$i]}" "$dest"
  done
fi

open_workspace "$mode" "$target_dir"

echo "Done."
echo "$target_dir"
