# task-env

Helpers for scaffolding dated task workspaces under `~/code/tasks/`.

## `bin/task-env.sh`

Creates a directory, clones one or more repositories into it, then opens the workspace in Cursor or Claude:

```text
~/code/tasks/{profile}/{yyyy-mm-dd}--{task-name}--{mode}/
```

### Usage

```bash
bin/task-env.sh <profile> <mode> <task-name> <repo> [repo...]
```

| Argument    | Description                                              |
|-------------|----------------------------------------------------------|
| `profile`   | Workspace profile (e.g. `work`, `personal`)              |
| `mode`      | `cursor` or `claude`                                     |
| `task-name` | Short label (spaces become hyphens in the path)          |
| `repo`      | Git URL, or GitHub `owner/repo` shorthand (cloned as `git@github.com:owner/repo.git`). `https://` and `http://` URLs are rewritten to SSH. Repeat, separated by spaces. One repo is cloned as the workspace directory; several are cloned as subdirectories under it. |

After cloning:

| Mode     | Opens with                                      |
|----------|-------------------------------------------------|
| `cursor` | `cursor .`                                      |
| `claude` | `claude --dangerously-skip-permissions`         |

### Example

```bash
bin/task-env.sh work cursor "fix login" octocat/Hello-World
# → ~/code/tasks/work/YYYY-MM-DD--fix-login--cursor/
# → runs: cursor .

bin/task-env.sh work cursor "fix login" octocat/Hello-World cli/cli
# → ~/code/tasks/work/YYYY-MM-DD--fix-login--cursor/Hello-World
# → ~/code/tasks/work/YYYY-MM-DD--fix-login--cursor/cli
# → runs: cursor .
```
