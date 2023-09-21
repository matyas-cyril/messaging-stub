#!/bin/bash

file_transport="transport_to_mbx"

function create_cpt {
    local user=$1
    local pwd=$2
    local dom=$3

    local err=0
    if [ -n ${dom} ]; then

        echo -n "${pwd}" | /usr/sbin/saslpasswd2 -c -p -u "${dom}" "${user}"
        if [ $? -ne 0 ]; then
            /usr/bin/logger -t $0 "ko: ${user}@${dom}"
            err=1
        else
            /usr/bin/logger -t $0 "ok: ${user}@${dom}" 
        fi

    else

        echo -n "${pwd}" | /usr/sbin/saslpasswd2 -c -p "${user}"
        if [ $? -ne 0 ]; then
            /usr/bin/logger -t $0 "ko: ${user}"
            err=1
        else
            /usr/bin/logger -t $0 "ok: ${user}" 
        fi

    fi

    return $err
}

function parse {
    local inputFile="$1"
    IFS=' '
    cpt=0
    err=0
    while IFS= read -r line; do
        cpt=$((cpt+1))
        data=($(echo -n $line | xargs))

        if [[ ${#data[@]} == 0 || ${data::1} == '#' ]]; then
            continue
        fi

        if [ ${#data[@]} != 2 ]; then
            /usr/bin/logger -t $0  "error line $cpt : $line"
            err=1
            continue
        fi

        user=''
        dom=''

        IFS='@'
        read -ra ADDR <<< ${data[0]}  
        for i in "${ADDR[@]}"; do
            if [ -z ${user} ]; then
                user="${i,,}"
            else
                dom="${i,,}"
            fi
        done
        IFS=' '
        pwd=${data[1]}

        if [[ -n ${user} && -n ${pwd} ]]; then
            create_cpt "${user}" "${pwd}" "${dom}"
            if [ $? -ne 0 ]; then
                err=1
            else
                if [[ ${user} != 'cyrus' && -n ${dom} ]]; then
                    echo "${user}@${dom}     lmtp:unix:/run/cyrus/socket/lmtp" >> /tmp/${file_transport}
                fi
            fi
        fi

    done < "${inputFile}"

    return $err
}

# Pas de fichiers !
if [ $# -eq 0 ]; then
    /usr/bin/logger -t $0 "no users to create"
    exit 0
fi

if [ ! -f $1 ]; then
    echo "file $1 no valid"
    exit 2
fi

err_processing=0
while [ $# -ne 0 ]; do
    file=$1; shift

    if [ ! -f $1 ]; then
        /usr/bin/logger -t $0 "file $file no valid"
        err_processing=1
        continue
    fi

    echo -n '' > /tmp/${file_transport}
    /usr/bin/logger -t $0 "processing file: $file"
    parse ${file}
    if [ $? -ne 0 ]; then
        /usr/bin/logger -t $0 "errors occurred during file $file processing" 
    else
        /usr/bin/logger -t $0 "end of file $file processing with success"
        sort /tmp/${file_transport} | uniq > /tmp/.${file_transport} && \
          mv -f /tmp/.${file_transport} /tmp/${file_transport}
        [ -s /tmp/${file_transport} ]
        if [ $? -eq 0 ]; then
            echo "*     discard:" >> /tmp/${file_transport}
            mv -f /tmp/${file_transport} /etc/postfix/${file_transport}
            postmap cdb:/etc/postfix/${file_transport} && /etc/init.d/postfix reload
            
            # Mode chroot
            ln /etc/sasldb2 /var/spool/postfix/etc/
        fi
    fi

done

exit $err_processing