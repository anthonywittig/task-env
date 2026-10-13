# task-env

Helpers for scaffolding dated task workspaces under `~/code/tasks/`.

## `bin/task-env.sh`

Creates a directory, optionally clones one or more repositories into it, then opens the workspace in Cursor or Claude:

```text
~/code/tasks/{profile}/{yyyy-mm-dd}--{task-name}--{mode}/
```

### Usage

```bash
bin/task-env.sh <profile> <mode> <task-name> [repo...]
```

| Argument    | Description                                              |
|-------------|----------------------------------------------------------|
| `profile`   | Workspace profile (e.g. `work`, `personal`)              |
| `mode`      | `cursor` or `claude`                                     |
| `task-name` | Short label (spaces become hyphens in the path)          |
| `repo`      | Optional. Git URL, or GitHub `owner/repo` shorthand (cloned as `git@github.com:owner/repo.git`). `https://` and `http://` URLs are rewritten to SSH. Repeat, separated by spaces. Omit to create an empty workspace. One repo is cloned as the workspace directory; several are cloned as subdirectories under it. |

After cloning:

| Mode     | Opens with                                      |
|----------|-------------------------------------------------|
| `cursor` | `cursor .`                                      |
| `claude` | `claude --dangerously-skip-permissions`         |

### Example

```bash
bin/task-env.sh work cursor "scratch notes"
# → ~/code/tasks/work/YYYY-MM-DD--scratch-notes--cursor/
# → runs: cursor .

bin/task-env.sh work cursor "fix login" octocat/Hello-World
# → ~/code/tasks/work/YYYY-MM-DD--fix-login--cursor/
# → runs: cursor .

bin/task-env.sh work cursor "fix login" octocat/Hello-World cli/cli
# → ~/code/tasks/work/YYYY-MM-DD--fix-login--cursor/Hello-World
# → ~/code/tasks/work/YYYY-MM-DD--fix-login--cursor/cli
# → runs: cursor .
```

### List and reopen

`-l` lists that profile's task directories, newest first. `-e` opens the numbered entry with the mode stored in its directory name (`cursor` or `claude`). Numbers match the current list and change when a newer task is added.

```bash
bin/task-env.sh work -l
# Tasks for work:
# 1  2026-10-12  ai-demo-v4  cursor
# 2  2026-10-09  fix-login   claude

bin/task-env.sh work -e 2
# → opens task 2 with claude
```

`--list` and `--execute` are the long forms.
