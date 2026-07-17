
##
# @file
# {{ PROJECT_NAME }} aliases.
#

##
# Start app dev.
#
function {{ SHORT_NAME }}app() {
  local dir="{{ PROJECT_PATH }}"

  echo
  echo "http://{{ HOSTNAME }}.localhost:8080"
  echo

  cd "$dir"

  nvm use

  if [[ -z "$1" ]]; then
    code .
  fi

  case "$1" in
    build)
      if [[ -d "$dir/docs" ]]; then
        rm -rf "$dir/docs"
      fi
      pnpm build
      ;;

    dev|start)
      pnpm "$1"
      ;;
  esac
}
