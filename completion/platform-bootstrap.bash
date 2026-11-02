_platform_bootstrap_completion() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local commands="
    list
    doctor
    check-ports
    bootstrap
    verify
    destroy
    kind-config
    kind-create
    kind-status
    kind-delete
    registry-create
    registry-delete
    registry-configure-kind
    registry-verify
    crossplane-install
    crossplane-verify
    crossplane-status
    crossplane-uninstall
    doctor-ai
    build-ai-node-image
    kind-ai-config
    kind-ai-create
    configure-ai-containerd
    install-ai-device-plugin
    verify-ai
    test-ai
    bootstrap-ai
  "

  local options="
    -n
    --name
    --http-port
    --https-port
    --registry-port
    -h
    --help
  "

  case "${prev}" in
    -n|--name)
      local state_root="${XDG_STATE_HOME:-${HOME}/.local/state}/platform-bootstrap"

      if [[ -d "${state_root}" ]]; then
        COMPREPLY=(
          $(compgen -W "$(find "${state_root}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')" -- "${cur}")
        )
      fi
      return
      ;;

    --http-port|--https-port|--registry-port)
      return
      ;;
  esac

  if [[ "${cur}" == -* ]]; then
    COMPREPLY=( $(compgen -W "${options}" -- "${cur}") )
  else
    COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
  fi
}

complete -F _platform_bootstrap_completion platform-bootstrap