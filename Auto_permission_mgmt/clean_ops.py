#!/usr/bin/env python3
# -*- coding:utf-8 -*-

from datetime import datetime, timedelta

import psycopg2
import pymysql

local_string = ['localhost', 60902, 'recovery', 'recovery', 'recovery']


def check_privs():
    data = []
    global local_string
    se_sql = """SELECT proj_name, db_type, proj_env, rol_name, rol_priv, db_grant
                FROM role_perm_expired
                WHERE rol_priv='rw' and role_expired >= current_timestamp - interval '7' day"""

    pgs_conn = psycopg2.connect(host=local_string[0],
                                port=local_string[1],
                                user=local_string[2],
                                password=local_string[3],
                                database=local_string[4])

    pgs_curs = pgs_conn.cursor()

    # check the expired time for each profile.
    pgs_curs.execute(se_sql)
    data = pgs_curs.fetchall()

    pgs_curs.close()
    return data


def clean_privs(conn_string):
    re_msql = """revoke ALTER, CREATE VIEW, CREATE, DELETE, DROP, GRANT OPTION, INDEX, INSERT, REFERENCES, 
    SELECT, SHOW VIEW, TRIGGER, UPDATE on {}.* from '{}'@'%';""".format(str(conn_string[10][0]), str(conn_string[5]))
    re_psql = "revoke {} from {};".format(str(conn_string[10][1] + '_' + conn_string[6]), str(conn_string[5]))

    de_psql = """DELETE FROM role_perm_expired WHERE rol_name='{}' and rol_priv='{}' and proj_name='{}' and proj_env='{}' and 
    db_type='{}' and db_grant[1]='{}'""".format(str(conn_string[5]), str(conn_string[6]), str(conn_string[7]),
                                         str(conn_string[8]), str(conn_string[9]), str(conn_string[10][0]))

    # print(re_msql, re_psql, de_psql, end='\n')
    global local_string
    if str(conn_string[9]) == 'pgs':
        target_conn = psycopg2.connect(host=conn_string[0],
                                       port=int(conn_string[1]),
                                       user=conn_string[2],
                                       password=conn_string[3],
                                       database=conn_string[4])
        tgt_curs = target_conn.cursor()
        tgt_curs.execute(re_psql)
        target_conn.commit()
        print('pgs')
    else:
        mys_conn = pymysql.connect(host=conn_string[0],
                                   port=int(conn_string[1]),
                                   user=conn_string[2],
                                   password=conn_string[3],
                                   db=conn_string[4])
        mys_curs = mys_conn.cursor()
        mys_curs.execute(re_msql)
        mys_conn.commit()
        print('mys')

    pgs_conn = psycopg2.connect(host=local_string[0],
                                port=local_string[1],
                                user=local_string[2],
                                password=local_string[3],
                                database=local_string[4])

    pgs_curs = pgs_conn.cursor()

    pgs_curs.execute(de_psql)
    pgs_conn.commit()
    
    pgs_curs.close()
        