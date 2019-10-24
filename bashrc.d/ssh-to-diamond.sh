#!/bin/bash

# set -e

_is_private_ip() {
    # Check if in private range
    #172.16.0.0 - 172.31.255.255
    IFS='.' read -ra ADDR <<< "${nx_addr}"

    if [[ 4 -ne "${#ADDR[@]}" ]]; then
        echo "Error: '$nx_addr' does not appear to be a valid ip"
        return 1
    fi

    if [[ ${ADDR[0]} -eq 172 ]]; then
        if [[ ${ADDR[1]} -ge 16 && ${ADDR[1]} -le 31 ]]; then
          return 0
        fi
    fi
    return 1
}

ssd() {
    if command -v getent >/dev/null; then
        nx_addr=$(getent hosts nx-staff.diamond.ac.uk | awk '{ print $1 }')
    elif command -v python >/dev/null; then
        nx_addr=$(python -c 'import socket; print([x[-1][0] for x in socket.getaddrinfo("nx-staff.diamond.ac.uk", 0)][0])')
    fi

    if _is_private_ip "${nx_addr}"; then
        # echo "Inside diamond"
        ssh "$@"
        # -i /var/jenkins_home/.ssh/id_rsa
    else
        echo "Outside diamond, connecting via nx-staff"
        # shellcheck disable=SC2088
        ssh -t mep23677@nx-staff.diamond.ac.uk ssh -Yi '~/.ssh/id_rsa_internal' "$@"
    fi
}


# internal
#ssh -i <key> <hostname>
#ssh -ti /var/jenkins_home/.ssh/id_rsa mep23677@nx-staff.diamond.ac.uk ssh -i <remote_key> <hostname>
#ssh -ti /var/jenkins_home/.ssh/id_rsa mep23677@nx-staff.diamond.ac.uk ssh -i '~/.ssh/id_rsa_internal' ws133 java -jar ~/bin/agent.jar