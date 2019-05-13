#!/bin/bash

pgbch='/usr/pgsql-10/bin/pgbench'

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

hst='172.31.19.42'
prt='60901'
usr='performance'
pwd='pgsqladmin'
dbn='performance'

function run_pgbench {
    pghst=$1
    pgprt=$2
    pgusr=$3
    pgdbn=$5
    pgtrd=$6
    export PGPASSWORD=$4
    $pgbch -M prepared -n -h${pghst} -p${pgprt} -U${pgusr} ${pgdbn} -T5 -c${pgtrd} -j${pgtrd}
}


LOGFILE=$(mktemp /tmp/pgbench_log.XXXXXXXXX)

thrd=40
while ((${thrd} < 480))
do
  run_pgbench ${hst} ${prt} ${usr} ${pwd} ${dbn} ${thrd} | tee -a ${LOGFILE}
  if [[ ${thrd} -lt 400 ]]
  then
      let thrd*=2
  else
      let thrd+=80
  fi

done
