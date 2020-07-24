#!/bin/bash

function check_dir() {
  local dir_name=$1
  local pkg_info_dir="${1}/${PACKAGE_INFO_DIR}"
  local dir_contents=$(ls $dir_name)

  if [[ -z $dir_contents ]]; then
    util_error "Package directory is empty"
    return 1
  fi

  if [[ -f "${pkg_info_dir}/package.info" ]]; then
    util_message "Found package.info file, default variables will be overwritten"
    . "${pkg_info_dir}/package.info"
  fi

  # check, if there are files other then package.info
  # if yes, then there are maintainter script or binary files to unpack

  if echo $dir_contents | grep -q "^${PACKAGE_INFO_DIR}$" && [[ ! -f "${pkg_info_dir}/scripts" ]]; then
    util_error "You need at least one file or dir to unpack, or maintainer postinst script"
    return 1
  fi

  for content in "${INCLUDES[@]}"
  do
    if [[ ( ${content} == "./" || ${content} == "." ) && ${#INCLUDES[*]} -gt 1 ]]; then
      util_error "INCLUDES array have './' option and its length not equal 1"
      util_error "If INCLUDES have './' option, which means all files, then it have to be the single element"
      return 1
    fi
  done

  if [[ $INCLUDES == "./" || $INCLUDES == "." ]]; then
    if echo $dir_contents | grep -q "^${PACKAGE_INFO_DIR}$"; then
      util_message "You set all files as the include, but directory ${dir_name} haven't any files except meta info."
    fi
  fi

  if [[ $INCLUDES != "./" ]]; then
    for content in "${INCLUDES[@]}"
    do
      if [[ ! -f "${DIR_NAME}/${content}" && ! -d "${DIR_NAME}/${content}" ]]; then
        util_error "Package dir haven't '${content}' file/directory from INCLUDES"
        return 1
      fi
    done
  fi

  return 0
}

function ask_unset() {
  if [[ -z $PKG_NAME ]]; then
    read -p "Please, input Package name: " user_input
    PKG_NAME=$user_input
  fi

  if [[ -z $MAINTAINER_NAME ]]; then
    if [[ -z $DEBFULLNAME ]]; then
      read -p "Please, input Maintainer name: " user_input
    else
      echo "Found \$DEBFULLNAME variable: ${DEBFULLNAME}"
      while true; do
        read -p "Do you want to use this name? [y/n]: " yn
        case $yn in
          [Yy]* )
            MAINTAINER_NAME=$DEBFULLNAME
            break
            ;;
          [Nn]* )
            read -p "Please, input Maintainer name: " user_input
            MAINTAINER_NAME=$user_input
            break
            ;;
          * )
            echo "Please, answer yes[y] or no[n]"
            ;;
        esac
      done
    fi
  fi

  if [[ -z $MAINTAINER_EMAIL ]]; then
    if [[ -z $DEBEMAIL ]]; then
      read -p "Please, input Maintainer e-mail: " user_input
    else
      echo "Found \$DEBEMAIL variable: ${DEBEMAIL}"
      while true; do
        read -p "Do you want to use this e-mail? [y/n]: " yn
        case $yn in
          [Yy]* )
            MAINTAINER_EMAIL=$DEBFULLEMAIL
            break
            ;;
          [Nn]* )
            read -p "Please, input Maintainer e-mail: " user_input
            MAINTAINER_EMAIL=$user_input
            break
            ;;
          * )
            echo "Please, answer yes[y] or no[n]"
            ;;
        esac
      done
    fi
  fi

  if [[ -z $ENDPOINT_DIR ]]; then
    read -p "Please, input Endpoint dir: " user_input
    ENDPOINT_DIR=$user_input
  fi
}

function scripts_find() {
  local scripts_file="${DIR_NAME}/${PACKAGE_INFO_DIR}/scripts"

  if [[ -f "${scripts_file}" ]]; then
    if grep -Eq "^function preinst\(\)[' '\t\n]" "${scripts_file}"; then
      util_message "preinst script found and will be injected"
      PREINST_SCRIPT="${scripts_file}"
    fi

    if grep -Eq "^function postinst\(\)[' '\t\n]" "${scripts_file}"; then
      util_message "postinst script found and will be injected"
      POSTINST_SCRIPT="${scripts_file}"
    fi

    if grep -Eq "^function prerm\(\)[' '\t\n]" "${scripts_file}"; then
      util_message "prerm script found and will be injected"
      PRERM_SCRIPT="${scripts_file}"
    fi

    if grep -Eq "^function postrm\(\)[' '\t\n]" "${scripts_file}"; then
      util_message "postrm script found and will be injected"
      POSTRM_SCRIPT="${scripts_file}"
    fi

    if grep -Eq "^function config\(\)[' '\t\n]" "${scripts_file}"; then
      util_message "config script found and will be injected"
      CONFIG_SCRIPT="${scripts_file}"
     fi
  fi

  if [[ -f "${DIR_NAME}/${PACKAGE_INFO_DIR}/questions.json" ]]; then
    util_message "question templates found and will be injected"
    TEMPLATES_SCRIPT="${DIR_NAME}/${PACKAGE_INFO_DIR}/questions.json"
  fi

  return 0
}

function license_check() {
  if [[ -f "${DIR_NAME}/${PACKAGE_INFO_DIR}/LICENSE" ]]; then
    util_message "license file found and will be injected"
    LICENSE_FILE="${DIR_NAME}/${PACKAGE_INFO_DIR}/LICENSE"
  fi
}