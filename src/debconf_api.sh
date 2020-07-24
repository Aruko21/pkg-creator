#!/bin/bash

function ask_question() {
  if [[ $# -eq 0 ]]; then
    echo "$0: Missed question name attribute"
    exit 1
  fi

  local question=$1


  export INPUT_STATUS=$(db_input critical "{{ PKG_NAME }}/${question}" ; echo $?) # Initialisation

  db_go || true # query printing

  db_get "{{ PKG_NAME }}/${question}"
}

function get_answer() {
  if [[ $# -eq 0 ]]; then
    echo "$0: Missed question name attribute"
    exit 1
  fi

  local question=$1

  db_get "{{ PKG_NAME }}/${question}"
}

function set_window_title() {
  if [[ $# -eq 0 ]]; then
    echo "$0: Missed message attribute"
    exit 1
  fi

  local message=$1
  db_title "${message}"
}

function cancel_install() {
  db_purge
  exit 1
}