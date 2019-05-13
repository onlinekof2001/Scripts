#!/bin/bash

sysb='/usr/local/bin/sysbench'

function timestamp {
    date +'%b %d %H:%M:%S'
}

function log {
    TYPE=$(echo $1 | tr '[:lower:]' '[:upper:]')
    shift
    echo "$(timestamp) $TYPE: ${*}" >> ${LOGFILE}
    if [[ "${TYPE}" == "FATAL" ]]; then
        exit 1
    fi
}

hst='mysql5725.cdncaqbxqkyv.rds.cn-north-1.amazonaws.com.cn'
prt='3306'
usr='mysqladmin'
dbn='performance'

function run_sysbench {
    mysqlhst=$1
    mysqlprt=$2
    mysqlusr=$3
    mysqlpwd=$4
    mysqldbn=$5
    mysqltrd=$6
    mysqlrwo=$7
    $sysb --mysql-host=${mysqlhst} --mysql-port=${mysqlprt} --mysql-user=${mysqlusr} --mysql-password=${mysqlpwd} --mysql-db=${mysqldbn} --threads=${mysqltrd} --time=180 --thread-stack-size=128k --percentile=0 ${mysqlrwo} run
}

LOGFILE=$(mktemp /tmp/sysbench_log.XXXXXXXXX)
read -p "Choose type [ oltp_read_only | oltp_read_write ]" rw_type

thrd=80
while ((${thrd} <= 480))
do
  run_sysbench ${hst} ${prt} ${usr} ${usr} ${dbn} ${thrd} ${rw_type} | tee -a ${LOGFILE}
  let thrd+=80
done
