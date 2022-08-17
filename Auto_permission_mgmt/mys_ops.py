#!/usr/bin/env python3
# -*- coding:utf-8 -*-

import pymysql
import psycopg2
from datetime import datetime, timedelta


def msql_exec(mys_string):
    # print(mys_string)
    update_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    expired_time = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d %H:%M:%S")
    dbs_idx: int = ''

    mys_conn = pymysql.connect(host=mys_string[0],
                               port=int(mys_string[1]),
                               user=mys_string[2],
                               password=mys_string[3].strip('\''),
                               db=mys_string[4])

    mys_curs = mys_conn.cursor()

    local_string = ['localhost',
                    60902,
                    'recovery',
                    'recovery',
                    'recovery']

    pgs_conn = psycopg2.connect(host=local_string[0],
                                port=local_string[1],
                                user=local_string[2],
                                password=local_string[3],
                                database=local_string[4])

    pgs_curs = pgs_conn.cursor()


    def insert_local(params):
        # print(params, expired_time)
        db_privs = '{' + params[5] + '}'
        in_sql = """INSERT INTO role_perm_expired(rol_name, rol_priv, proj_name, proj_env, db_type, db_grant, role_expired) 
                    VALUES ('{p_role}', '{p_privs}', '{p_proj}', '{p_env}', '{p_type}', '{db_grant}', '{utime}') 
                    ON CONFLICT (rol_name, proj_name, db_grant, rol_priv, db_type) 
                    DO UPDATE SET role_expired = '{utime}'""".format(p_role=str(params[0]),
                                                                     p_privs=str(params[1]),
                                                                     p_proj=str(params[2]),
                                                                     p_env=str(params[3]),
                                                                     p_type=str(params[4]),
                                                                     db_grant=db_privs,
                                                                     utime=expired_time)
        return in_sql

    # defined read and write permission
    ro_sql = "grant SELECT, SHOW VIEW on %s.* to %s@'%'"
    rw_sql = """grant ALTER, CREATE VIEW, CREATE, DELETE, DROP, GRANT OPTION, INDEX, INSERT, REFERENCES, 
                SELECT, SHOW VIEW, TRIGGER, UPDATE on {}.* to {}@'%';"""

    se_sql = "select schema_name from information_schema.schemata where schema_name not regexp 'schema|sys|mysql|recycle'"
   

    if 'all' in mys_string[10] and (mys_string[6] == 'ro' or mys_string[6] == 'rw'):
        mys_curs.execute(se_sql)
        dbs = mys_curs.fetchall()
        for dbs_idx in range(0, len(dbs)):
            # print(dbs[dbs_idx][0], str(mys_string[5]))
            if mys_string[6] == 'ro':
                ro_sql = "grant SELECT, SHOW VIEW on {}.* to {}@'%'".format(str(dbs[dbs_idx][0]), str(mys_string[5]))
                mys_curs.execute(ro_sql)
                mys_conn.commit()
            elif mys_string[6] == 'rw':
                rw_sql = """grant ALTER, CREATE VIEW, CREATE, DELETE, DROP, GRANT OPTION, INDEX, INSERT, REFERENCES, 
                SELECT, SHOW VIEW, TRIGGER, UPDATE on {}.* to {}@'%';""".format(str(dbs[dbs_idx][0]), str(mys_string[5]))
                mys_curs.execute(rw_sql)
                mys_conn.commit()
            l_param = [mys_string[5], mys_string[6], mys_string[7], mys_string[8], mys_string[9], dbs[dbs_idx][0]]
            pgs_curs.execute(insert_local(l_param))
            pgs_conn.commit()
    elif mys_string[6] == 'ro' or mys_string[6] == 'rw':
        for dbs_idx in range(0, len(mys_string[10])):
            # print(mys_string[10][dbs_idx], str(mys_string[5]))
            if mys_string[6] == 'ro':
                ro_sql = "grant SELECT, SHOW VIEW on {}.* to {}@'%'".format(str(mys_string[10][dbs_idx]), str(mys_string[5]))
                mys_curs.execute(ro_sql)
                mys_conn.commit()
            elif mys_string[6] == 'rw':
                rw_sql = """grant ALTER, CREATE VIEW, CREATE, DELETE, DROP, GRANT OPTION, INDEX, INSERT, REFERENCES, 
                SELECT, SHOW VIEW, TRIGGER, UPDATE on {}.* to {}@'%';""".format(str(mys_string[10][dbs_idx]), str(mys_string[5]))
                mys_curs.execute(rw_sql)
                mys_conn.commit()
            l_param = [mys_string[5], mys_string[6], mys_string[7], mys_string[8], mys_string[9], mys_string[10][dbs_idx]]
            print(l_param)
            pgs_curs.execute(insert_local(l_param))
            pgs_conn.commit()


    mys_conn.close()
    pgs_conn.close()