#!/usr/bin/env bash

if [[ ${PUBLIC_KEY} ]]; then
    mkdir -p ${HOME}/.ssh
    echo ${PUBLIC_KEY} >> ${HOME}/.ssh/authorized_keys
    chmod 700 -R ${HOME}/.ssh
    service ssh start
fi
