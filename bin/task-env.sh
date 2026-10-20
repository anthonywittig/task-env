#!/usr/bin/env bash
# task-env.sh — scaffold a dated task workspace and optionally clone repos into it.
#
# Usage:
#   task-env.sh <profile> <mode> <task-name> [repo...]
#   task-env.sh <profile> -l
#   task-env.sh <profile> -e <number>
#
# Arguments:
#   profile    Workspace profile (e.g. work, personal)
#   mode       cursor | claude — which tool to open after creating
#   task-name  Short task label (spaces become hyphens in the path)
#   repo       Optional clone target: git URL, or GitHub owner/repo shorthand.
#              HTTP(S) URLs are rewritten to SSH.
#              Pass more than one, separated by spaces.
#              Omit to create an empty workspace.
#   -l         List task directories for the profile, newest first
#   -e <n>     Open task number n from that list
#
# Creates:
#   ~/code/tasks/{profile}/{yyyy-mm-dd}--{task-name}--{mode}/
# With no repo, that directory is empty. Each repo is cloned as a subdirectory
# under it, named from the repo.
# Then the workspace opens:
#   cursor  → cursor .
#   claude  → claude --dangerously-skip-permissions

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  task-env.sh <profile> <mode> <task-name> [repo...]
  task-env.sh <profile> -l|--list
  task-env.sh <profile> -e|--execute <number>

  profile    Workspace profile (e.g. work, personal)
  mode       cursor | claude
  task-name  Short task label (spaces become hyphens)
  repo       Optional. Git URL, or GitHub owner/repo shorthand.
             HTTP(S) URLs are cloned over SSH.
             Repeat for more than one repo, separated by spaces.
             Omit to create an empty workspace.
  -l         List tasks for the profile, newest first
  -e <n>     Open task number n from that list

With no repo, the workspace directory is empty. Each repo is cloned as a
subdirectory under it, named from the repo.

Then opens the workspace:
  cursor  → cursor .
  claude  → claude --dangerously-skip-permissions

Examples:
  task-env.sh work cursor "scratch notes"
  → ~/code/tasks/work/2026-07-31--scratch-notes--cursor/

  task-env.sh work cursor "fix login" owner/repo
  → ~/code/tasks/work/2026-07-31--fix-login--cursor/repo

  task-env.sh work cursor "fix login" owner/api owner/web
  → ~/code/tasks/work/2026-07-31--fix-login--cursor/api
  → ~/code/tasks/work/2026-07-31--fix-login--cursor/web

  task-env.sh work -l
  task-env.sh work -e 2
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
      # The task-env.zsh wrapper sets this so Claude starts in the calling
      # shell, which a script cannot cd.
      if [[ -n "${TASK_ENV_CD_FILE:-}" ]]; then
        printf '%s\n' "$target_dir" > "$TASK_ENV_CD_FILE"
        return 0
      fi
      claude --dangerously-skip-permissions
      ;;
    *)
      die "mode must be 'cursor' or 'claude' (got: $mode)"
      ;;
  esac
}

# Split {yyyy-mm-dd}--{task}--{mode} into TASK_DATE, TASK_NAME, and TASK_MODE.
parse_task_dir_name() {
  local base=$1
  if [[ ! "$base" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})--(.+)--(cursor|claude)$ ]]; then
    die "unrecognized task directory: $base"
  fi
  TASK_DATE=${BASH_REMATCH[1]}
  TASK_NAME=${BASH_REMATCH[2]}
  TASK_MODE=${BASH_REMATCH[3]}
}

# Fill TASK_DIRS with workspace paths for a profile, newest directory name first.
load_task_dirs() {
  local profile=$1
  local dir="${HOME}/code/tasks/${profile}"
  local path name sorted
  local names=()
  TASK_DIRS=()
  [[ -d "$dir" ]] || return 0

  for path in "$dir"/*; do
    [[ -d "$path" ]] || continue
    names+=("$(basename "$path")")
  done
  [[ ${#names[@]} -gt 0 ]] || return 0

  sorted=$(printf '%s\n' "${names[@]}" | sort -r)
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    parse_task_dir_name "$name"
    TASK_DIRS+=("${dir}/${name}")
  done <<< "$sorted"
}

list_tasks() {
  local profile=$1
  local path width=0 i=1 num_width
  load_task_dirs "$profile"
  if [[ ${#TASK_DIRS[@]} -eq 0 ]]; then
    echo "No tasks for ${profile}."
    return 0
  fi

  for path in "${TASK_DIRS[@]}"; do
    parse_task_dir_name "$(basename "$path")"
    [[ ${#TASK_NAME} -gt $width ]] && width=${#TASK_NAME}
  done
  num_width=${#TASK_DIRS[@]}
  num_width=${#num_width}

  echo "Tasks for ${profile}:"
  for path in "${TASK_DIRS[@]}"; do
    parse_task_dir_name "$(basename "$path")"
    printf '%*d  %s  %-*s  %s\n' "$num_width" "$i" "$TASK_DATE" "$width" "$TASK_NAME" "$TASK_MODE"
    i=$((i + 1))
  done
}

execute_task() {
  local profile=$1
  local raw=$2
  local number count path
  [[ "$raw" =~ ^[0-9]+$ ]] || die "task number must be a positive integer (got: $raw)"
  number=$((10#$raw))
  [[ "$number" -ge 1 ]] || die "task number must be a positive integer (got: $raw)"

  load_task_dirs "$profile"
  count=${#TASK_DIRS[@]}
  [[ "$count" -gt 0 ]] || die "no tasks for ${profile}"
  [[ "$number" -le "$count" ]] || die "task number ${number} is out of range (1-${count})"

  path=${TASK_DIRS[$((number - 1))]}
  parse_task_dir_name "$(basename "$path")"
  open_workspace "$TASK_MODE" "$path"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

profile_raw=$1
shift
profile=$(slugify "$profile_raw")
[[ -n "$profile" ]] || die "profile is empty after sanitizing"

if [[ $# -ge 1 ]]; then
  case "$1" in
    -l|--list)
      [[ $# -eq 1 ]] || die "-l does not take extra arguments"
      list_tasks "$profile"
      exit 0
      ;;
    -e|--execute)
      [[ $# -eq 2 ]] || die "-e requires a task number"
      execute_task "$profile" "$2"
      echo "Done."
      echo "${TASK_DIRS[$((10#$2 - 1))]}"
      exit 0
      ;;
  esac
fi

if [[ $# -lt 2 ]]; then
  usage >&2
  exit 1
fi

mode_raw=$1
task_raw=$2
shift 2
repos=("$@")

mode=$(slugify "$mode_raw")
task=$(slugify "$task_raw")

[[ -n "$mode" ]] || die "mode is empty after sanitizing"
[[ -n "$task" ]] || die "task-name is empty after sanitizing"

case "$mode" in
  cursor|claude) ;;
  *) die "mode must be 'cursor' or 'claude' (got: $mode_raw)" ;;
esac

repo_urls=()
repo_dirs=()
if [[ ${#repos[@]} -gt 0 ]]; then
  for repo in "${repos[@]}"; do
    [[ -n "$repo" ]] || die "repo is required"
    repo_urls+=("$(resolve_repo_url "$repo")")
  done
fi

if [[ ${#repo_urls[@]} -gt 0 ]]; then
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

if [[ ${#repo_urls[@]} -gt 0 ]]; then
  for i in "${!repo_urls[@]}"; do
    dest="${target_dir}/${repo_dirs[$i]}"
    echo "Cloning ${repo_urls[$i]} → $dest"
    git clone "${repo_urls[$i]}" "$dest"
  done
fi

open_workspace "$mode" "$target_dir"

echo "Done."
echo "$target_dir"
