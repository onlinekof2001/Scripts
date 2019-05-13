#!/bin/bash

function timeline() {
    date=$(date +%c)
}
brc='barman.conf'


#Review the barman installation and version



function bar_conf() {
    # add option on barman configuration
    if [ -z $1 ]
	then
	    cat >> /etc/$brc << EOF
[barman]
barman_home = /barman
barman_user = barman
log_file = /var/log/barman/barman.log
configuration_files_directory = /etc/barman.d
minimum_redundancy = 1
retention_policy = REDUNDANCY 1
EOF
	fi
}


