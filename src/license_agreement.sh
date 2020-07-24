#!/bin/bash

function ask_agreement() {
  ask_question "{{ PKG_NAME }}/license"
  get_answer "{{ PKG_NAME }}/license"

  if [[ $RET == "false" ]]; then
    exit 0
  fi
}

function check_agreement() {
  get_answer "{{ PKG_NAME }}/license"

  if [[ $RET == "false" ]]; then
    cancel_install
  fi
}