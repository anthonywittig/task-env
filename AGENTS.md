# AGENTS.md

## Cursor Cloud specific instructions

This repository is a small collection of bash helpers (no Node/Python package manager).

### Run / demo

- Script entrypoint: `bin/task-env.sh`
- Requires `bash`, `git`, network access to the clone target, and either the `cursor` or `claude` CLI (depending on `mode`)
- Creates workspaces under `~/code/task-env/{profile}/{yyyy-mm-dd}--{task}--{mode}/` and clones into that path
- `mode` must be `cursor` or `claude`:
  - `cursor` → `cd` into the workspace and run `cursor .`
  - `claude` → `cd` into the workspace and run `claude --dangerously-skip-permissions`
- `repo` accepts a full git URL or GitHub `owner/repo` shorthand (expanded to `https://github.com/owner/repo.git`)
- Profile, mode, and task name are slugified (lowercase, spaces → hyphens, unsafe path chars stripped)
- Cloud VMs typically do not have `cursor`/`claude` installed; smoke-test with PATH stubs that log argv if needed

### Lint / test

- Syntax check: `bash -n bin/task-env.sh`
- Smoke test: run against a public repo (e.g. `octocat/Hello-World`) with mode `cursor` or `claude`, then remove the created directory under `~/code/task-env/` if desired
