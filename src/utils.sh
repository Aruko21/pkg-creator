#!/bin/bash

# Trap non-normal exit signals:
function err_handler() {
  # '$1 if set, or $? by default' expression
  local exit_status=${1:-$?}
  echo "Error occured in script '${0}'. Error code: ${exit_status} (line ${BASH_LINENO}: '${BASH_COMMAND}')"
  exit "$exit_status"
}

function util_message() {
  if [[ $# -eq 0 ]]; then
    echo "Missed message argument"
    return 1
  fi

  local bold_esc="\033[1m"
  local reset_esc="\033[0m"

  echo -e "${bold_esc}pkg-creator:${reset_esc} ${1}"
}

function util_error() {
  if [[ $# -eq 0 ]]; then
    echo "Missed message argument"
    return 1
  fi

  local bold_esc="\033[1m"
  local red_esc="\033[31m"
  local reset_esc="\033[0m"

  echo -e "${bold_esc}pkg-creator: ${red_esc}error:${reset_esc} ${1}"
}