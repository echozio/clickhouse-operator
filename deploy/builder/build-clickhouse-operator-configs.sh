#!/bin/bash

# Compose clickhouse-operator .yaml manifest from components

# Paths
CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(realpath "${CUR_DIR}/../..")"

# Relative and abs paths where templates live
TEMPLATES_PATH="deploy/builder/templates-config"
TEMPLATES_DIR="${PROJECT_ROOT}/${TEMPLATES_PATH}"

# Relative and abs paths where users.d templates live
TEMPLATES_USERSD_PATH="${TEMPLATES_PATH}/users.d"
TEMPLATES_USERSD_DIR="${PROJECT_ROOT}/${TEMPLATES_USERSD_PATH}"

# Relative and abs paths where config live
CONFIG_PATH="config"
CONFIG_DIR="${1:-"${PROJECT_ROOT}/${CONFIG_PATH}"}"

source "${CUR_DIR}/lib/lib.sh"

#
# Renders config file with all variables
#
function render_file() {
    local src="${1}"
    local dst="${2}"

    # Render header
    if [[ "${dst: -4}" == ".xml" ]]; then
        cat <<EOF > "${dst}"
<!-- IMPORTANT -->
<!-- This file is auto-generated -->
<!-- Do not edit this file - all changes would be lost -->
<!-- Edit appropriate template in the following folder: -->
<!-- ${TEMPLATES_PATH} -->
<!-- IMPORTANT -->
EOF
    elif [[ "${dst: -5}" == ".yaml" ]]; then
        cat <<EOF > "${dst}"
# IMPORTANT
# This file is auto-generated
# Do not edit this file - all changes would be lost
# Edit appropriate template in the following folder:
# ${TEMPLATES_PATH}
# IMPORTANT
EOF
    else
        echo -n "" > "${dst}"
    fi
    # Render file body
    cat "${src}" | \
        WATCH_NAMESPACES="${WATCH_NAMESPACES:-""}" \
        CH_USERNAME_PLAIN="${CH_USERNAME_PLAIN:-""}" \
        CH_PASSWORD_PLAIN="${CH_PASSWORD_PLAIN:-""}" \
        CH_CREDENTIALS_SECRET_NAMESPACE="${CH_CREDENTIALS_SECRET_NAMESPACE:-""}" \
        CH_CREDENTIALS_SECRET_NAME="${CH_CREDENTIALS_SECRET_NAME:-"clickhouse-operator"}" \
        VERBOSITY="${VERBOSITY:-"1"}" \
        envsubst \
        >> "${dst}"
}

# Process files in the root folder
# List files only
for f in $(ls -pa "${TEMPLATES_DIR}" | grep -v /); do
    # Source
    SRC_FILE_PATH=$(realpath "${TEMPLATES_DIR}/${f}")
    FILE_NAME=$(basename "${SRC_FILE_PATH}")

    # Destination
    mkdir -p "${CONFIG_DIR}"
    DST_FILE_PATH=$(realpath "${CONFIG_DIR}/${FILE_NAME}")

    #echo "${SRC_FILE_PATH} ======> ${DST_FILE_PATH}"
    render_file "${SRC_FILE_PATH}" "${DST_FILE_PATH}"
done

# Process files in sub-folders
for SUB_TEMPLATES_DIR in $(ls -d "${TEMPLATES_DIR}"/*/); do
    # List files only
    for f in $(ls -pa "${SUB_TEMPLATES_DIR}" | grep -v /); do
        # Source
        SRC_FILE_PATH=$(realpath "${SUB_TEMPLATES_DIR}/${f}")
        SUB_DIR=$(basename "${SUB_TEMPLATES_DIR}")
        FILE_NAME=$(basename "${SRC_FILE_PATH}")

        # Destination
        SUB_CONFIG_DIR=$(realpath "${CONFIG_DIR}/${SUB_DIR}")
        mkdir -p "${SUB_CONFIG_DIR}"
        DST_FILE_PATH=$(realpath "${SUB_CONFIG_DIR}/${FILE_NAME}")

        #echo "${SRC_FILE_PATH} ======> ${DST_FILE_PATH}"
        render_file "${SRC_FILE_PATH}" "${DST_FILE_PATH}"
    done
done
