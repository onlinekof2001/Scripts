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

read -p "Choose SQL drive [ mysql | pgsql ]" sqldrv

if [ $sqldrv = 'mysql' ]
then
hst='mysql5725.cdncaqbxqkyv.rds.cn-north-1.amazonaws.com.cn'
prt='3306'
usr='mysqladmin'
dbn='performance'
pwd=$usr
else
hst='postgresqlbench.postgres.database.chinacloudapi.cn'
prt='5432'
usr='pgsqladmin@'
dbn='performance'
pwd='Decathlon2018'
fi

function init_sysbench {
    mysqlhst=$1
    mysqlprt=$2
    mysqlusr=$3
    mysqlpwd=$4
    mysqldbn=$5
    mysqlrwo=$6
    mysqlrow=$7
    if [ $sqldrv = 'mysql' ]
    then
        $mysqlc -h${mysqlhst} -P${mysqlprt} -u${mysqlusr} -D mysql --password=${mysqlpwd} -e "create database ${mysqldbn}"
        $sysb --mysql-host=${mysqlhst} --mysql-port=${mysqlprt} --mysql-user=${mysqlusr} --mysql-password=${mysqlpwd} --mysql-db=${mysqldbn} ${mysqlrwo} --table_size ${mysqlrow}
    else
        export PGPASSWORD=${mysqlpwd}
        $psqlc -h${mysqlhst} -p${mysqlprt} -U${mysqlusr} postgres -c "create database ${mysqldbn}"
        $sysb --db-driver=pgsql --pgsql-host=${mysqlhst} --pgsql-port=${mysqlprt} --pgsql-user=${mysqlusr} --pgsql-password=${mysqlpwd} --pgsql-db=${mysqldbn} ${mysqlrwo} --table_size ${mysqlrow}
    fi
}

function run_sysbench {
    mysqlhst=$1
    mysqlprt=$2
    mysqlusr=$3
    mysqlpwd=$4
    mysqldbn=$5
    mysqltrd=$6
    mysqlrwo=$7
	mysqltim=$8
    if [ $sqldrv = 'mysql' ]
    then
    $sysb --mysql-host=${mysqlhst} --mysql-port=${mysqlprt} --mysql-user=${mysqlusr} --mysql-password=${mysqlpwd} --mysql-db=${mysqldbn} --threads=${mysqltrd} --time=${mysqltim} --thread-stack-size=128k --percentile=0 ${mysqlrwo} run
    else
    $sysb --db-driver=pgsql --pgsql-host=${mysqlhst} --pgsql-port=${mysqlprt} --pgsql-user=${mysqlusr} --pgsql-password=${mysqlpwd} --pgsql-db=${mysqldbn} --threads=${mysqltrd} --time=${mysqltim} --percentile=0 ${mysqlrwo} run
    fi
}

LOGFILE=$(mktemp /tmp/sysbench_log_${sqldrv}.XXXXXXXXX)
read -p "Initial test database [y|n]: " opt
opt=$(echo ${opt} | tr '[:upper:]' '[:lower:]')

read -p "Choose type [ oltp_read_only | oltp_read_write ]" rw_type

if [[ $opt = 'y' ]]
then 
read -p "table_rows [Value of rows]: " scale
init_sysbench ${hst} ${prt} ${usr} ${pwd} ${dbn} ${scale}
fi

read -p "Max concurrency threads [ 240 - 1260 ]: " conns
thrd=$conns

time=600
for ((i=3;i>0;i++))
do
  last_time=$((${i}*${time}))
  run_sysbench ${hst} ${prt} ${usr} ${pwd} ${dbn} ${thrd} ${rw_type} ${last_time} | tee -a ${LOGFILE}
  sleep $((${time}/10))s
done
