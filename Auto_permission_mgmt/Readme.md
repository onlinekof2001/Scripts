# Create a role table to recording the role granted action 

```sql
CREATE TABLE recovery.role_perm_expired (
    role_id bigserial,
    proj_name character varying(30),
    db_type character(8),
    proj_env character(3),
    rol_name character varying(50),
    rol_priv character(2),
    db_grant text[],
    role_expired timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE ONLY recovery.role_perm_expired
    ADD CONSTRAINT role_perm_expired_pkey PRIMARY KEY (role_id);


CREATE UNIQUE INDEX idx_role_perm_expired_i1 ON recovery.role_perm_expired USING btree (rol_name, proj_name, db_grant, rol_priv, db_type);
```

# Usage of the role grant script on Rundeck or other platform 
```bash
ansible-playbook -i ${ASB_HOME}/${RD_OPTION_INVENTORY} ${ASB_HOME}/db_actions.yml -e "{db_groups: bar01_Azure, \
db_action: 'db_actions/permission_mgmt', dbs_type: '${RD_OPTION_01_DB_TYPE}', dbs_env: '${RD_OPTION_02_DB_ENVIRONMENT}', \
dbs_inst: '${RD_OPTION_03_PROJECT_NAME}', cli_user: '${RD_OPTION_04_USER_GRANTED}', perm_grant: '${RD_OPTION_06_GRANT_PERM}', \
db_granted: '${RD_OPTION_07_DB_GRANTED}', dbs_email: '${RD_OPTION_05_EMAIL_ADDRESSES}'}" -v

```

# Main task
```python
python3 {{ dbs_path }}/grant_main.py '{{ dbs_inst }}' '{{ dbs_type }}' '{{ dbs_env }}' '{{ cli_user }}' '{{ perm_grant }}' '{{db_granted}}' '{{ dbs_email }}'
```
