#!/usr/bin/env python3
# -*- coding:utf-8 -*-

def conn_info(conn_dir, db_home, puser, privs, db_grant):
    conn_cfg_lst = ['set_admin.sh', 'set_administrator.sh', 'set_avnadmin.sh', 'set_barman.sh']
    db_conn_cfg = ''
    # get all connection parameter from the folder
    # print(conn_dir.split('_')[0])

    if conn_dir.split('_')[3] == 'rds':
        if conn_dir.split('_')[2] == 'pgs':
            db_conn_cfg = conn_cfg_lst[1]
        else:
            db_conn_cfg = conn_cfg_lst[0]
    elif conn_dir.split('_')[3] == 'vm':
        db_conn_cfg = conn_cfg_lst[3]
    elif conn_dir.split('_')[3] == 'aiv':
        db_conn_cfg = conn_cfg_lst[2]

    conn_file = db_home + '/' + conn_dir + '/' + db_conn_cfg

    conn_str = []
    num: int = 0
    with open(conn_file, 'r') as cf:
        for cline in cf:
            if cline.find('export') >= 0:
                conn_str.append(cline.strip('\n').split()[1])
            num += 1
    cf.close()

    db_host = conn_str[0].split('=')[1]
    db_port = conn_str[1].split('=')[1]
    db_user = conn_str[2].split('=')[1].strip('\'')
    db_passwd = conn_str[3].split('=')[1].strip('\'')
    db_name = conn_str[4].split('=')[1] if num >= 4 else None
    p_grant = privs if len(privs) != 0 else 'ro'
    db_proj = conn_dir.split('_')[1]
    db_env = conn_dir.split('_')[4]
    db_type = conn_dir.split('_')[2]

    # Notice: db_grant is a list, need to be handle one by one, if there is more than one element in the list.
    db_string = [
                db_host, 
                db_port,
                db_user,
                db_passwd,
                db_name,
                puser,
                p_grant,
                db_proj,
                db_env,
                db_type,
                db_grant
    ]
    
    # print(db_string)
    return db_string
