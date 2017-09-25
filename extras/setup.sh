#!/usr/bin/env bash

cd "$(dirname $0)/.."

# Paths
python_req_file="extras/python_requirements.txt"
roles_req_file="roles/requirements.yml"
update_roles_script="extras/update_roles.sh"
vault_password_file=".vault_password_file"

function cleanup() {
    local retval=0
}

function die() {
    local retval=1

    # Check if it has args
    if [ $# -gt 0 ]; then
        # See if first arg is integer
        if [[ "$1" =~ ^-?[0-9]+$ ]]; then
            # First arg is integer (exit status)
            retval=$1
            shift
        fi
        # Remaining args are the message
        [ $# -gt 0 ] && echo -e "$@"
    fi

    cleanup
    exit $retval
}

function askYesNo() {
        QUESTION=$1
        DEFAULT=$2
        if [ "$DEFAULT" = true ]; then
                OPTIONS="[Y/n]"
                DEFAULT="y"
            else
                OPTIONS="[y/N]"
                DEFAULT="n"
        fi
        read -p "$QUESTION $OPTIONS " -n 1 -s -r INPUT
        INPUT=${INPUT:-${DEFAULT}}
        echo ${INPUT}
        if [[ "$INPUT" =~ ^[yY]$ ]]; then
            ANSWER=true
        else
            ANSWER=false
        fi
}

function getPassword()
{
    while [ -z "$PASSWORD" ]
    do
        echo "Please enter a password:" >&2
        read -s PASSWORD1
        echo "Please re-enter the password to confirm:" >&2
        read -s PASSWORD2

        if [ "$PASSWORD1" == "$PASSWORD2" ]; then
            PASSWORD=$PASSWORD1
        else
            # Output error message in red
            red='\033[0;31m'
            NC='\033[0m' # No Color
            echo -e "\n${red}Passwords did not match!${NC}" >&2
        fi
        unset $PASSWORD1 $PASSWORD2
    done
}

# Check prerequisites
[ -z "$(which python)" ] && die 1 "Cannot find python in your path."
[ -z "$(which pip)" ] && die 1 "Cannot find pip in your path."
[ -z "$(which ansible-galaxy)" ] && die 1 "Cannot find ansible-galaxy in your path."
[ -z "$(which ansible-vault)" ] && die 1 "Cannot find ansible-vault in your path."

# Install Python requirements
if [ "$(whoami)" == "root" ]; then
    pip install --no-cache-dir --upgrade --requirement "$python_req_file"
else
    sudo -H pip install --no-cache-dir --upgrade --requirement "$python_req_file"
fi

# Create vault password file and encrypt vault
if [ ! -f "$vault_password_file" ]; then
    getPassword
    touch "$vault_password_file"
    chmod 0600 "$vault_password_file"
    echo "$PASSWORD" > "$vault_password_file"
    ansible-vault encrypt --vault-password-file "$vault_password_file" group_vars/all/vault
else
    echo "Vault password file already exists. Skipping vault setup." >&2
fi

# Update roles
askYesNo "Would you like to update external roles?" true
UPDATE_ROLES=$ANSWER
if [ "$UPDATE_ROLES" = true ]; then
    $update_roles_script
fi

echo "Done."
exit 0

