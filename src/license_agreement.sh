#!/bin/bash

function ask_agreement() {
  ask_question "license"
  get_answer "license"

  if [[ $RET == "false" ]]; then
    exit 0
  fi
}

function check_agreement() {
  get_answer "license"

  if [[ $RET == "false" ]]; then
    cancel_install
  fi
}