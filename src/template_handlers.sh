#!/bin/bash

function inject_debconf_api(){
  if [[ $# -eq 0 ]]; then
    echo "$0: Missed template file argument"
    exit 1
  fi

  local template_file=$1

  local tmp_file="tmp_api_injecting"

  echo "# -------- BEGIN OF INTERNAL DEBCONF API SECTION" > $tmp_file
  sed -e "/^[' '\t]*#/d" "${SRC_DIR}/debconf_api.sh" >> $tmp_file
  echo -e "\n# -------- END OF INTERNAL DEBCONF API SECTION" >> $tmp_file

  sed -i -e "/{{ API_SCRIPTS }}/{
    r ${tmp_file}
    d
  }" $template_file

  rm $tmp_file
}

function inject_license_checkers() {
  if [[ $# -eq 0 ]]; then
    echo "$0: Missed template file argument"
    exit 1
  fi

  local template_file=$1
  local tmp_file="tmp_api_injecting"

  echo "# -------- BEGIN OF INTERNAL LICENSE API SECTION" > $tmp_file
  sed -e "/^[' '\t]*#/d" "${SRC_DIR}/license_agreement.sh" >> $tmp_file
  echo -e "\n# -------- END OF INTERNAL LICENSE API SECTION" >> $tmp_file

  sed -i -e "/{{ LICENSE_SCRIPTS }}/{
    r ${tmp_file}
    d
  }" $template_file

  rm $tmp_file
}

function inject_scripts() {
  if [[ $# -eq 0 ]]; then
    echo "$0: Missed source and template file arguments"
    exit 1
  fi

  if [[ $# -eq 1 ]]; then
    echo "$0: Missed template file argument"
    exit 1
  fi

  local source_file=$1
  local template_file=$2
  local call_script=${3:-""}

  if [[ -z $source_file ]]; then
    sed -i -e "/{{ CUSTOM_SCRIPT }}/d" -e "/{{ CUSTOM_SCRIPT_CALL }}/d" $template_file
    sed -i -e "/{{ API_SCRIPTS }}/d" $template_file
  else
    inject_debconf_api $template_file

    local tmp_file="tmp_functions_sed_handling"

    echo "# -------- BEGIN OF USER SCRIPTS SECTION" >> $tmp_file
    sed -e "/^[' '\t]*#/d" $source_file >> $tmp_file
    echo -e "\n# -------- END OF USER SCRIPTS SECTION" >> $tmp_file

    sed -i -e "/{{ CUSTOM_SCRIPT }}/{
      r ${tmp_file}
      d
    }" $template_file

    rm $tmp_file

    sed -i -e "s/{{ CUSTOM_SCRIPT_CALL }}/${call_script}/" $template_file
  fi
}

function inject_questions() {
  if [[ $# -eq 0 ]]; then
    echo "$0: Missed source and template file arguments"
    exit 1
  fi

  if [[ $# -eq 1 ]]; then
    echo "$0: Missed template file argument"
    exit 1
  fi

  local source_file=$1
  local template_file=$2

  if [[ ! -z $source_file ]]; then
    local tmp_file="tmp_quests_parsed"

    "${SRC_DIR}/json_to_quests.py" $source_file $tmp_file

    if [[ $? -ne 0 ]]; then
      util_error "Error while parsing questions.json"
      exit 1
    fi

    cat $tmp_file >> $template_file

    rm $tmp_file
  fi
}

function inject_license() {
  if [[ $# -eq 0 ]]; then
    echo "$0: Missed license path and debian dir arguments"
    exit 1
  fi

  if [[ $# -eq 1 ]]; then
    echo "$0: Missed debian dir argument"
    exit 1
  fi

  local license_file=$1
  local debian_dir=$2

  local templates_file="${debian_dir}/templates"
  local preinst_script="${debian_dir}/preinst"
  local config_script="${debian_dir}/config"

  if [[ -z $license_file ]]; then
    sed -i -e "/{{ LICENSE_SCRIPTS }}/d" $preinst_script
    sed -i -e "/{{ LICENSE_SCRIPTS }}/d" $config_script
    sed -i -e "/{{ LICENSE_AGREEMENT }}/d" $preinst_script
    sed -i -e "/{{ LICENSE_AGREEMENT }}/d" $config_script
  else
    echo -e "Template: {{ PKG_NAME }}/license" > $templates_file
    echo -e "Type: boolean" >> $templates_file
    echo -e "Description: License agreement" >> $templates_file

    local ifs_default=$IFS
    while IFS= read -r line
    do
      echo -e "  ${line}" >> $templates_file
    done < "$license_file"

    IFS=$ifs_default

    echo -e "" >> $templates_file

    inject_license_checkers $config_script
    inject_license_checkers $preinst_script

    if [[ -z $PREINST_SCRIPT ]]; then
      inject_debconf_api $preinst_script
    fi

    if [[ -z $CONFIG_SCRIPT ]]; then
      inject_debconf_api $config_script
    fi

    sed -i -e "s/{{ LICENSE_AGREEMENT }}/ask_agreement/" $config_script
    sed -i -e "s/{{ LICENSE_AGREEMENT }}/check_agreement/" $preinst_script
  fi
}

function template_handle() {
  if [[ $# -eq 0 ]]; then
    echo "$0: Missed file_path argument"
    exit 1
  fi

  local source_path=$1

  # if no patterns
  if ! grep -Eq "{{ [A-Za-z0-9_-]+ }}" "${source_path}"; then
    return 0
  fi

  local matches=($(grep -Pno "(?<={{ )[A-Za-z0-9_-]+(?= }})" "${source_path}"))

  # save the default IFS delimiter
  local default_ifs=$IFS

  for template in ${matches[@]}
    do
      IFS=':'
      read -ra number_pattern <<< "${template}"

      local str_number=${number_pattern[0]}
      local variable=${number_pattern[1]}

      sed -i -e "${str_number}s!{{ ${variable} }}!${!variable}!" $1

    done

  # set IFS to default
  IFS=$default_ifs

  return 0
}