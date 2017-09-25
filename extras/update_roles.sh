#!/usr/bin/env bash

cd "$(dirname $0)/.."

roles_dir="$(readlink -f roles/external)"
roles_req_file="$(readlink -f roles/requirements.yml)"

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

#Check prerequisites
[ -z "$(which ansible-galaxy)" ] && die 1 "Cannot find ansible-galaxy in your path."

# Remove roles
cd "$roles_dir" || die 1 "Could not change to external roles directory."
if [ "$(pwd)" == "$roles_dir" ];then
    echo "Removing existing roles..."
    rm -rf *
fi

# (Re)install roles
ansible-galaxy install -r "$roles_req_file" --force --no-deps -p "$roles_dir"

echo "Done."
exit 0

