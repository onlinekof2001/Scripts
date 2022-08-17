#!/usr/bin/env python3
# -*- coding:utf-8 -*-

from datetime import datetime, timedelta

import psycopg2
import time


def psql_exec(pgs_string):
    update_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    expired_time = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d %H:%M:%S")
    rol_data = ''
    db_data = ''

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

    # defined read and write permission
    role_sql = "select rolname from pg_roles where rolname ilike %s"

    # get all the database in the instance.
    se_psql = """SELECT datname FROM pg_database pd JOIN pg_roles pa ON pd.datdba = pa.oid  
    WHERE not datistemplate and not rolsuper"""

    # get all schema in each database.
    shm_sql = """select catalog_name, schema_name from information_schema.schemata 
    where schema_name !~ 'pg_.*|^information'"""

    ro_sql = "grant select on all tables in schema {} to {}"
    rw_sql = "grant all on all tables in schema {} to {}"
    cr_sql = "create role {}"
    pr_sql = "grant {} to {}"

    def insert_local(params):
        # print(params, expired_time)
        db_privs = '{' + ','.join(params[5]) + '}'
        print(db_privs)
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

    def granted_shm(db_list):
        dbs_idx: int = ''
        sch_idx: int = ''
        # handle right by schema
        for dbs_idx in range(0, len(db_list)):
            print(db_list[dbs_idx][0])
            schem_conn = psycopg2.connect(host=pgs_string[0],
                                          port=int(pgs_string[1]),
                                          user=pgs_string[2],
                                          password=pgs_string[3].strip('\''),
                                          database=db_list[dbs_idx][0])
            schem_curs = schem_conn.cursor()
            schem_curs.execute(shm_sql)
            schemas = schem_curs.fetchall()

            for sch_idx in range(0, len(schemas)):
                l_param = [pgs_string[5], pgs_string[6], pgs_string[7], pgs_string[8], pgs_string[9], schemas[sch_idx]]
                print(l_param)
                schem_curs.execute(role_sql, ('%' + schemas[sch_idx][1] + '_' + pgs_string[6] + '%',))
                schema_role = schem_curs.fetchall()
                if len(schema_role) == 0:
                    schem_curs.execute(cr_sql.format(schemas[sch_idx][1] + '_' + pgs_string[6]))
                    schem_curs.execute(ro_sql.format(schemas[sch_idx][1], schemas[sch_idx][1] + '_' + pgs_string[6]) if pgs_string[6] == 'ro' else rw_sql.format(schemas[sch_idx][1], schemas[sch_idx][1] + '_' + pgs_string[6]))
                    schem_curs.execute(pr_sql.format(schemas[sch_idx][1] + '_' + pgs_string[6], pgs_string[5]))
                    schem_conn.commit()
                else:
                    schem_curs.execute(pr_sql.format(schemas[sch_idx][1] + '_' + pgs_string[6], pgs_string[5]))
                    schem_conn.commit()

                pgs_curs.execute(insert_local(l_param))
                pgs_conn.commit()
        
        schem_conn.close()

        return l_param

    # get all dbs
    target_conn = psycopg2.connect(host=pgs_string[0],
                                   port=int(pgs_string[1]),
                                   user=pgs_string[2],
                                   password=pgs_string[3],
                                   database=pgs_string[4])
    tgt_curs = target_conn.cursor()

    if 'all' in pgs_string[10] and (pgs_string[6] == 'ro' or pgs_string[6] == 'rw'):
        tgt_curs.execute(se_psql)
        dbs = tgt_curs.fetchall()
        granted_shm(dbs)
    elif pgs_string[6] == 'ro' or pgs_string[6] == 'rw':
        dbs = []
        for item in range(0, len(pgs_string[10])):
            dbs.append((pgs_string[10][item],))
        # print(dbs)
        granted_shm(dbs)

    target_conn.close()
    # # check list of databases first, if no database in the list, default is all, will find all non-system db,
    # # then grant permission to the user.
    # if 'all' in pgs_string[10] and (pgs_string[6] == 'ro' or pgs_string[6] == 'rw'):
    #     tgt_curs.execute(se_psql)
    #     dbs = tgt_curs.fetchall()
    #     for dbs_idx in range(0, len(dbs)):
    #         # normally, each db should have two permission roles db_ro & db_rw,
    #         # confirm that whether the role exist or not,
    #         # create the role will it doesn't exist.
    #         tgt_curs.execute(role_sql, ('%' + dbs[dbs_idx][0] + '_' + pgs_string[6] + '%',))
    #         l_param = [pgs_string[5], pgs_string[6], pgs_string[7], pgs_string[8], pgs_string[9], dbs[dbs_idx][0]]
    #         dbs_role = tgt_curs.fetchall()
    #         if len(dbs_role) == 0:
    #             cr_sql = """create role {} """.format(dbs[dbs_idx][0] + '_' + pgs_string[6])
    #             tgt_curs.execute(cr_sql)
    #             target_conn.commit()
    #             p_sql = "grant {} to {};".format(str(dbs[dbs_idx][0] + '_' + pgs_string[6]), str(pgs_string[5]))
    #             tgt_curs.execute(p_sql)
    #             target_conn.commit()
    #         else:
    #             p_sql = "grant {} to {};".format(str(dbs_role[0][0]), str(pgs_string[5]))
    #             tgt_curs.execute(p_sql)
    #             target_conn.commit()
    #         pgs_curs.execute(insert_local(l_param))
    #         pgs_conn.commit()
    # elif pgs_string[6] == 'ro' or pgs_string[6] == 'rw':
    #     for dbs_idx in range(0, len(pgs_string[10])):
    #         print(pgs_string[10][dbs_idx] + '_' + pgs_string[6])
    #         tgt_curs.execute(role_sql, ('%' + pgs_string[10][dbs_idx] + '_' + pgs_string[6] + '%',))
    #         dbs_role = tgt_curs.fetchall()
    #         l_param = [pgs_string[5], pgs_string[6], pgs_string[7], pgs_string[8], pgs_string[9], pgs_string[10][dbs_idx]]
    #         print(l_param)
    #         if len(dbs_role) == 0:
    #             cr_sql = """create role {} """.format(pgs_string[10][dbs_idx] + '_' + pgs_string[6])
    #             tgt_curs.execute(cr_sql)
    #             target_conn.commit()
    #             p_sql = "grant {} to {};".format(str(pgs_string[10][dbs_idx] + '_' + pgs_string[6]), str(pgs_string[5]))
    #             tgt_curs.execute(p_sql)
    #             target_conn.commit()
    #         else:
    #             p_sql = "grant {} to {};".format(str(dbs_role[0][0]), str(pgs_string[5]))
    #             tgt_curs.execute(p_sql)
    #             target_conn.commit()
    #         pgs_curs.execute(insert_local(l_param))
    #         pgs_conn.commit()               

    if __name__ == '__main__':
        # begin = time.time()
        try:
            # main()
            end = time.time()
            print("耗时 ", end - begin)
            print("文件生成完毕")
        except Exception as e:
            print("错误: ", e)
