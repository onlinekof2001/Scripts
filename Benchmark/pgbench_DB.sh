#!/bin/bash

pgbch='/usr/pgsql-10/bin/pgbench'
psqlc='/usr/pgsql-10/bin/psql'
versn=$(hostnamectl | awk '/Operating System/{ print $(NF-1)}')
osbrd=$(hostnamectl | grep -c 'Red Hat')

function timestamp {
    date +'%b %d %H:%M:%S'
}

function log {
    TYPE=$(echo $1 | tr '[:lower:]' '[:upper:]')
    shift
    echo "$(timestamp) $TYPE: ${*}" | tee -a ${LOGFILE}
    if [[ "${TYPE}" == "FATAL" ]]; then
        exit 1
    fi
}


if [[ ! -x $pgbch ]]
then
   if [[ $versn -le 7 ]] || [[ $osbrd -eq 0 ]]
   then
       log print "Install pgbench for PostgreSQL on CentOS"
       yum install -y https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm
       yum install -y postgresql10-contrib
   else
       log print "Install pgbench for PostgreSQL on Red Hat"
       yum install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-redhat10-10-2.noarch.rpm
       yum install -y postgresql10-contrib
   fi
fi

hst='12.xxx.xxx.xxx'
prt='xxxx'
usr='performance'
pwd='pgsqladmin'
dbn='performance'

function init_pgbench {
    pghst=$1
    pgprt=$2
    pgusr=$3
    pgdbn=$5
    pgscl=$6
    export PGPASSWORD=$4
    $psqlc -h${pghst} -p${pgprt} -U${pgusr} postgres -c "create database performance"
    $pgbch -i -s ${pgscl} -h${pghst} -p${pgprt} -U${pgusr} ${pgdbn} 
}

function run_pgbench {
    pghst=$1
    pgprt=$2
    pgusr=$3
    pgdbn=$5
    pgtrd=$6
    pgtim=$7
    export PGPASSWORD=$4
    $pgbch -M prepared -b -n -h${pghst} -p${pgprt} -U${pgusr} ${pgdbn} -T${pgtim} -c${pgtrd} -j${pgtrd}
}


LOGFILE=$(mktemp /tmp/pgbench_log.XXXXXXXXX)

read -p "Initial test database [y|n]: " opt
opt=$(echo ${opt} | tr '[:upper:]' '[:lower:]')

if [[ $opt = 'y' ]]
then 
    read -p "scale * 100000 = table_rows [Value of Scale]: " scale
    init_pgbench ${hst} ${prt} ${usr} ${pwd} ${dbn} ${scale}
fi

read -p "Max concurrency threads [ 240 - 1260 ]: " conns
thrd=$conns

time=600
for ((i=1;i<4;i++))
do
  last_time=$((${i}*${time}))
  run_pgbench ${hst} ${prt} ${usr} ${pwd} ${dbn} ${thrd} ${last_time} | tee -a ${LOGFILE}
  sleep $((${time}/10))s
done
