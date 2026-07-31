# task-env

Helpers for scaffolding dated task workspaces under `~/code/task-env/`.

## `bin/create-task-env`

Creates a directory and clones a repository into it:

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
| `mode`      | Task mode (e.g. `debug`, `feature`, `review`)            |
| `repo`      | Git URL, or GitHub `owner/repo` shorthand                |
| `task-name` | Short label (spaces become hyphens in the path)          |

### Example

```bash
bin/create-task-env work feature octocat/Hello-World "fix login"
# → ~/code/task-env/work/YYYY-MM-DD--fix-login--feature/
```
