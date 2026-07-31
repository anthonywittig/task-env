# task-env

Helpers for scaffolding dated task workspaces under `~/code/task-env/`.

## `bin/create-task-env`

Creates a directory, clones a repository into it, then opens the workspace in Cursor or Claude:

```text
~/code/task-env/{profile}/{yyyy-mm-dd}--{task-name}--{mode}/
```

### Usage

```bash
bin/create-task-env <profile> <mode> <repo> <task-name>
```

| Argument    | Description                                              |
|-------------|----------------------------------------------------------|
| `profile`   | Workspace profile (e.g. `work`, `personal`)              |
| `mode`      | `cursor` or `claude`                                     |
| `repo`      | Git URL, or GitHub `owner/repo` shorthand                |
| `task-name` | Short label (spaces become hyphens in the path)          |

After cloning:

| Mode     | Opens with                                      |
|----------|-------------------------------------------------|
| `cursor` | `cursor .`                                      |
| `claude` | `claude --dangerously-skip-permissions`         |

### Example

```bash
bin/create-task-env work cursor octocat/Hello-World "fix login"
# → ~/code/task-env/work/YYYY-MM-DD--fix-login--cursor/
# → runs: cursor .
```
