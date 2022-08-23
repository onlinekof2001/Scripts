#!/bin/bash

sysb='/usr/local/bin/sysbench'
connf='/tmp/db_mapping_string'

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

# Choose DB type to do the benchmark.
read -p "Choose SQL drive [ mysql | pgsql ]" sqldrv

# Read database connection strings from connection file. the file format should be host:port:user:secretkey:dbname
conns=($(tr ':' ' ' < ${connf}))
hst=${conns[0]}
prt=${conns[1]}
usr=${conns[2]}
dbn=${conns[3]}
pwd=${conns[4]}

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
while [ ${thrd} -le '240' ] ; do
    for ((i=1;i<4;i++))
    do 
       last_time=$((${i}*${time}))
       run_sysbench ${hst} ${prt} ${usr} ${pwd} ${dbn} ${thrd} ${rw_type} ${last_time} | tee -a ${LOGFILE}
       sleep $((${time}/10))s
    done
    thrd = $(let ${thrd} += 80)
done 
