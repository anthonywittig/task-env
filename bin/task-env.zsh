# task-env.zsh — source from ~/.zshrc so the shell ends up in the workspace.
#
# A script cannot change its caller's directory. This function runs
# task-env.sh, then cds here. Claude is launched in this shell so it stays
# in the foreground. Splits, new tabs, and the next prompt all start in the
# workspace.

_task_env_script=${${(%):-%x}:A:h}/task-env.sh

task-env() {
  local cd_file dir action ret
  local -a lines
  cd_file=$(mktemp -t task-env) || return
  TASK_ENV_CD_FILE=$cd_file "$_task_env_script" "$@"
  ret=$?
  lines=("${(@f)$(<"$cd_file")}")
  dir=${lines[1]:-}
  action=${lines[2]:-}
  rm -f "$cd_file"
  (( ret == 0 )) || return $ret
  [[ -n $dir ]] || return 0
  cd "$dir" || return
  if [[ $action == resume ]]; then
    claude --dangerously-skip-permissions --resume "${dir:t}"
  elif [[ $action == claude ]]; then
    claude --dangerously-skip-permissions --name "${dir:t}"
  fi
}
