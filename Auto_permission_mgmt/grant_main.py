#!/usr/bin/env python3
# -*- coding:utf-8 -*-

import sys
import re

from mys_ops import msql_exec
from pgs_ops import psql_exec
from conn_proj import conn_info
from clean_ops import clean_privs, check_privs

# get all args from os env
if len(sys.argv) < 1:
    print('There are %s parameters gaven, project name, dbtype, user, grants must be given' % (len(sys.argv)))
else:
    param = sys.argv
    # proj: param[1], db_type: param[2], db_env: param[3], p_user: param[4], p_grant: param[5], db_grant: param[6]

db_lst = list(param[6].split(','))

def conn_folder(params):
    conn_fd = []
    db_home = ''
    db_ful_type = ''
    dbtype_l = ['pgs', 'mys', 'mdb']
    # read connection mapping file to get connection list /opt/.db_x_mapping.lst
    if params[2] in dbtype_l:
        map_f = '/opt/.db_' + params[2] + '_mapping.lst'
        if params[2] == 'pgs':
            db_ful_type = 'postgres'
        elif params[2] == 'mys':
            db_ful_type = 'mysql'
        elif params[2] == 'mdb':
            db_ful_type = 'mongod'

        # fetch db home path
        with open('/etc/passwd', 'r') as h_path:
            for home_path in h_path:
                if home_path.find(db_ful_type) >= 0:
                    # print(home_path.find(db_ful_type))
                    db_home = home_path.split(':')[5]
                    # print(db_home)

        h_path.close()

        # get db connection folder from the connection list
        with open(map_f, 'r') as fd:
            for fd_i in fd:
                if len(re.findall(params[1] + '.*' + params[3], fd_i)) > 0:
                    conn_fd.append(fd_i.strip('\n'))

            # print('read file %s %s' % (map_f, conn_fd))

        fd.close()

    return conn_fd, db_home


if __name__ == '__main__':
    # Read Only & Read Write operation or Clean up permission operation
    if param[5].lower() == 'ro' or param[5].lower() == 'rw':
        fd_lst = conn_folder(param)

        # each project may has two more env, then there are more than two connection folders
        # each folder will handle operation once.
        for i in range(0, len(fd_lst[0])):
            if param[2] == 'mys' and param[3] in fd_lst[0][i]:
                if len(param[4].split(',')) > 1:
                    for usr_idx in range(0, len(param[4].split(','))):
                        msql_exec(conn_info(fd_lst[0][i], fd_lst[1], param[4].split(',')[usr_idx].lower(), param[5], db_lst))
                else:
                    msql_exec(conn_info(fd_lst[0][i], fd_lst[1], param[4].lower(), param[5], db_lst))
            elif param[2] == 'pgs' and param[3] in fd_lst[0][i]:
                # print(fd_lst[0][i], fd_lst[1], param[4], param[5])
                psql_exec(conn_info(fd_lst[0][i], fd_lst[1], param[4].lower(), param[5], db_lst))
    else:
        cl_lst = check_privs()
        for inst in range(0, len(cl_lst)):
            cl_tup = list(cl_lst[inst])
            cl_tup.insert(0, 'check_privs.py')
            cl_fd = conn_folder(cl_tup)
            # print(cl_fd[0][0], cl_fd[1], cl_tup[4], cl_tup[5], cl_tup[6])
            # cl_fd[0][0]: the folder of the db connection, same as conn_fd, folfer should be inside the home path of database
            # cl_fd[1]: home path of database same as db_home
            # cl_tup[4]: profile info
            # cl_tupe[5]: p_grant, default only rw need to be clean up
            # cl_tup[6]: DB & schema information in a list such as [db, schema], for mysql only DB information.
            clean_privs(conn_info(cl_fd[0][0], cl_fd[1], cl_tup[4].lower(), cl_tup[5], cl_tup[6]))
