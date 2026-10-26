# AGENTS.md

## Cursor Cloud specific instructions

This repository is a small collection of bash helpers (no Node/Python package manager).

### Run / demo

- Script entrypoint: `bin/task-env.sh`
- Requires `bash`, `git`, network access to the clone target, and either the `cursor` or `claude` CLI (depending on `mode`)
- Creates workspaces under `~/code/tasks/{profile}/{yyyy-mm-dd}--{task}--{mode}/`. Usage is `task-env.sh <profile> <mode> <task-name> [repo...]`. With no repo, the directory is empty. Each repo is cloned as a subdirectory under it
- `task-env.sh <profile> -l` lists that profile's task directories newest first (numbered). `task-env.sh <profile> -e <number>` opens that entry with the mode in its directory name (`--list` and `--execute` are equivalent). Claude entries resume the session named after the directory (`claude --resume <directory>`)
- `mode` must be `cursor` or `claude`:
  - `cursor` → `cd` into the workspace and run `cursor .`
  - `claude` → `cd` into the workspace and run `claude --dangerously-skip-permissions --name <directory>`, where `<directory>` is the workspace directory name (for example `2026-10-23--elevance-health--claude`). Sourcing `bin/task-env.zsh` defines a `task-env` zsh function that cds into the workspace for every mode (via `TASK_ENV_CD_FILE`). Claude is launched from that function so it stays in the foreground; other modes are launched by the script. Terminal splits then start in the workspace
- `repo` accepts a full git URL or GitHub `owner/repo` shorthand (expanded to `git@github.com:owner/repo.git`). `https://` and `http://` clone URLs are rewritten to SSH (`git@host:path`)
- Profile, mode, and task name are slugified (lowercase, spaces → hyphens, unsafe path chars stripped)
- Cloud VMs typically do not have `cursor`/`claude` installed; smoke-test with PATH stubs that log argv if needed

### Lint / test

- Syntax check: `bash -n bin/task-env.sh`
- Smoke test: run against a public repo (e.g. `octocat/Hello-World`) with mode `cursor` or `claude`, then remove the created directory under `~/code/tasks/` if desired
