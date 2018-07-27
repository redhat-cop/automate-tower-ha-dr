#!/usr/bin/env bash

# This script runs setup for Ansible Tower.
# It determines how Tower is to be installed, gives the proper command,
# and then executes the command if asked.

# -------------
# Initial Setup
# -------------

# Cause exit codes to trickle through piping.
set -o pipefail

# When using an interactive shell, force colorized output from Ansible.
if [ -t "0" ]; then
    ANSIBLE_FORCE_COLOR=True
fi

# Set variables.
TIMESTAMP=$(date +"%F-%T")
LOG_DIR="/var/log/tower"
LOG_FILE="${LOG_DIR}/failover-${TIMESTAMP}.log"
TEMP_LOG_FILE='failover.log'

# --------------
# Usage
# --------------

function usage() {
    cat << EOF
Usage: $0 [Options]

Options:
  -c CURRENT_INVENTORY_FILE     Path to ansible inventory file
  -d DR_INVENTORY_FILE          Path to DR inventory file
  -h                    Show this help message and exit

Ansible Options:
EOF
    exit 64
}


# --------------
# Option Parsing
# --------------
FAILBACK=0
SETUP_SHORTCUT=0
BACKUP_FILE=""
# Process options to setup.sh
while getopts 'c:d:b:r' opt; do
    case ${opt} in
        c)
            CURRENT_INVENTORY_FILE=$(realpath $OPTARG)
            ;;
        d)
            DR_INVENTORY_FILE=$(realpath $OPTARG)
            ;;
        r)
            BACKUP_FILE=$(realpath $OPTARG)
            ;;
        *)
            usage
            ;;
    esac
done


echo "CURRENT_INVENTORY_FILE ${CURRENT_INVENTORY_FILE}"
echo "DR_INVENTORY_FILE ${DR_INVENTORY_FILE}"
# Change to the running directory for tower conf file and inventory file
# defaults.
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Sanity check: Test to ensure that an inventory file exists.
if [ ! -f "${CURRENT_INVENTORY_FILE}" ]; then
    cat << EOF
    No current inventory file could be found at ${CURRENT_INVENTORY_FILE}.
		echo "specify one manually with -c.
EOF
    usage
    exit 64
fi

# Sanity check: Test to ensure that an inventory file exists.
if [ ! -f "${DR_INVENTORY_FILE}" ]; then
    cat << EOF
    No current inventory file could be found at ${DR_INVENTORY_FILE}.
		echo "specify one manually with -d.
EOF
    usage
    exit 64
fi

export PYTHONUNBUFFERED=x
export ANSIBLE_FORCE_COLOR=$ANSIBLE_FORCE_COLOR
export ANSIBLE_ERROR_ON_UNDEFINED_VARS=True

TMP_VAULT_FILE=$(mktemp)
echo "$(openssl rand -base64 12)" > ${TMP_VAULT_FILE}
KEY_VAULT_FILE=tower_secret_key_vault

echo "GET SECRET KEY FROM TOWER OR BACKUP"

if [ "${BACKUP_FILE}" = "" ]; then

  _EXTRA_VARS=" \
    vault_pass_file="${TMP_VAULT_FILE}"
    key_vault_file="${KEY_VAULT_FILE}"
  "
else

  _EXTRA_VARS=" \
    vault_pass_file="${TMP_VAULT_FILE}"
    key_vault_file="${KEY_VAULT_FILE}"
    tower_backup_file="${BACKUP_FILE}"
  "
fi

ansible-playbook -i "${CURRENT_INVENTORY_FILE}" -v \
    tower_dr_prep.yml -e "${_EXTRA_VARS}" 2>&1 | tee $TEMP_LOG_FILE

ansible-playbook -i "${CURRENT_INVENTORY_FILE}" -v \
    tower_dr_setup.yml -e "${_EXTRA_VARS}" --vault-password-file=${TMP_VAULT_FILE} 2>&1 | tee $TEMP_LOG_FILE
