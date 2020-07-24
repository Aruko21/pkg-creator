#!/bin/bash

#set -e # fail on any non-null exit code from command
set -E # let shell functions inherit ERR trap

#DEFAULT_CONFIG_DIR="/etc/default"
#echo "SOME TEEEEEEEST"

export DEFAULT_CONFIG_DIR="$(cd $(dirname $(readlink -f ${0}))/../ && pwd)"
DEFAULT_CONFIG_NAME="pkg-creator.cfg"

export PACKAGE_INFO_DIR="PKGINFO"

if [[ -f "${DEFAULT_CONFIG_DIR}/${DEFAULT_CONFIG_NAME}" ]]; then
  . "${DEFAULT_CONFIG_DIR}/${DEFAULT_CONFIG_NAME}"
else
  echo "pkg-creator: error: Default configuration file '${DEFAULT_CONFIG_DIR}/${DEFAULT_CONFIG_NAME}' not found."
  echo "Please, run 'dpkg-reconfigure pkg-creator' for create a new one, or reinstall the package"
  exit 1
fi

. "${SRC_DIR}/package_validation.sh"
. "${SRC_DIR}/template_handlers.sh"
. "${SRC_DIR}/utils.sh"

#trap err_handler SIGHUP SIGINT SIGQUIT SIGTERM ERR

if [[ $# -eq 0 ]]; then
  DIR_NAME="./"
else
  DIR_NAME=$1
fi

if [[ ! -d $DIR_NAME ]]; then
  util_error "Directory '${DIR_NAME}' doesn't exist"
  exit 1
fi

if ! check_dir $DIR_NAME; then
  util_error "Package directory doesn't meet requirements. Please, change directory contents and try again"
  exit 1
fi

ask_unset

export PREINST_SCRIPT=""
export POSTINST_SCRIPT=""
export PRERM_SCRIPT=""
export POSTRM_SCRIPT=""
export CONFIG_SCRIPT=""
export TEMPLATES_SCRIPT=""
export LICENSE_FILE=""

scripts_find
license_check

PACKAGE_DEB_NAME="${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}"

DEB_DIR="${PKG_NAME}/DEBIAN"
BIN_DIR="${PKG_NAME}/${ENDPOINT_DIR}/${PKG_NAME}"

mkdir -p "$DEB_DIR"

rsync -a "${TEMPLATES_DIR}/" "${DEB_DIR}/"

inject_license "${LICENSE_FILE}" "${DEB_DIR}"
inject_scripts "${PREINST_SCRIPT}" "${DEB_DIR}/preinst" "preinst"
inject_scripts "${POSTINST_SCRIPT}" "${DEB_DIR}/postinst" "postinst"
inject_scripts "${PRERM_SCRIPT}" "${DEB_DIR}/prerm" "prerm"
inject_scripts "${POSTRM_SCRIPT}" "${DEB_DIR}/postrm" "postrm"
inject_scripts "${CONFIG_SCRIPT}" "${DEB_DIR}/config" "config"
inject_questions "${TEMPLATES_SCRIPT}" "${DEB_DIR}/templates"

template_handle "${DEB_DIR}/postinst"
template_handle "${DEB_DIR}/preinst"
template_handle "${DEB_DIR}/prerm"
template_handle "${DEB_DIR}/postrm"
template_handle "${DEB_DIR}/config"
template_handle "${DEB_DIR}/templates"
template_handle "${DEB_DIR}/control"

chmod -R 755 "$DEB_DIR"

mkdir -p "$BIN_DIR"

if [[ ! -z $INCLUDES ]]; then
  if [[ $INCLUDES != "./" && $INCLUDES != "." ]]; then
    for content in "${INCLUDES[@]}"
    do
      rsync -a "${DIR_NAME}/${content}" "${BIN_DIR}/${content}"
    done
  else
    rsync -a "${DIR_NAME}/" "${BIN_DIR}/" --exclude "${PACKAGE_INFO_DIR}" --exclude "${PKG_NAME}"
  fi
fi

dpkg-deb --build "$PKG_NAME"
mv "$PKG_NAME".deb "$PACKAGE_DEB_NAME".deb

rm -rf "$PKG_NAME"

exit 0
