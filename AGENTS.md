# AGENTS.md

## Cursor Cloud specific instructions

This repository is a small collection of bash helpers (no Node/Python package manager).

### Run / demo

- Script entrypoint: `bin/create-task-env`
- Requires `bash`, `git`, and network access to the clone target
- Creates workspaces under `~/code/task-env/{profile}/{yyyy-mm-dd}--{task}--{mode}/` and clones into that path
- `repo` accepts a full git URL or GitHub `owner/repo` shorthand (expanded to `https://github.com/owner/repo.git`)
- Profile, mode, and task name are slugified (lowercase, spaces → hyphens, unsafe path chars stripped)

### Lint / test

- Syntax check: `bash -n bin/create-task-env`
- Smoke test: run against a public repo (e.g. `octocat/Hello-World`), then remove the created directory under `~/code/task-env/` if desired
