#!/bin/bash

# backup_innodb_cluster.sh - backup a MySQL InnoDB Cluster

# (c) lefred 2019 - use at your own risk

# Use <mysql_config_editor> to save the credentials:
#   mysql_config_editor set --login-path=client
#                       --user=clusteradmin --password

# History
# -------
# 2020-10-01 : v3 fix hostname in checkStatus
# 2021-09-02 : v4 double -h in checkStatus

VERSION="0.4"

QUEUE_TRESHOLD=10000

# set the name of this machine as recognized in the cluster
hostname=$(hostname -s)

# function to get the primary 
getPrimary() {
     PRIMARY=$(mysql -BN -h $hostname -e "select member_host from performance_schema.replication_group_members where member_role='PRIMARY' limit 1" 2>/dev/null)  
     if [ $? -ne 0 ]
     then
        >&2 echo "Connection to $hostname not possible.... aborting!"
        exit 3
     fi
     echo $PRIMARY    
}
primary=$(getPrimary)
if [ $? -ne 0 ]
then
   exit 3
fi
if [ "$primary" == "" ]
then
   echo "No primary master... aborting!"
   exit 4
fi
# sleep 5sec to allow backup to start on secondary
if [ "$primary" == "$hostname" ]
then
  sleep 5 
fi


# function to check if the database is there
checkTable() {
   mysql -B -h $hostname -e "select * from information_schema.tables 
              where table_schema='mysql' and table_name=
              'backup_group' limit 1" | grep backup_group >/dev/null
   if [ $? -ne 0 ] 
   then
      mysql -B -h $primary -e "create table mysql.backup_group( 
                             hostname varchar(120) primary key, 
                             state varchar(10), 
			     started_at timestamp)"
   fi     
}

checkView() {
  mysql -B -h $hostname -e "select count(*) from information_schema.tables 
             where table_type='VIEW' 
             and table_schema='sys' and 
             table_name='gr_member_routing_candidate_status'" | grep '1' >/dev/null
  if [ $? -ne 0 ]
  then
     mysql -B -h $primary -e "USE sys;

DELIMITER $$

CREATE FUNCTION my_id() RETURNS TEXT(36) DETERMINISTIC NO SQL RETURN (SELECT @@global.server_uuid as my_id);$$

CREATE FUNCTION gr_member_in_primary_partition()
    RETURNS VARCHAR(3)
    DETERMINISTIC
    BEGIN
      RETURN (SELECT IF( MEMBER_STATE='ONLINE' AND ((SELECT COUNT(*) FROM
    performance_schema.replication_group_members WHERE MEMBER_STATE NOT IN ('ONLINE', 'RECOVERING')) >=
    ((SELECT COUNT(*) FROM performance_schema.replication_group_members)/2) = 0),
    'YES', 'NO' ) FROM performance_schema.replication_group_members JOIN
    performance_schema.replication_group_member_stats USING(member_id) where member_id=my_id());
END$$

CREATE VIEW gr_member_routing_candidate_status AS SELECT
sys.gr_member_in_primary_partition() as viable_candidate,
IF( (SELECT (SELECT GROUP_CONCAT(variable_value) FROM
performance_schema.global_variables WHERE variable_name IN ('read_only',
'super_read_only')) != 'OFF,OFF'), 'YES', 'NO') as read_only,
Count_Transactions_Remote_In_Applier_Queue as transactions_behind, Count_Transactions_in_queue as 'transactions_to_cert' 
from performance_schema.replication_group_member_stats where member_id=my_id();$$

DELIMITER ;"
  fi
}

getTheBackup() {
  mysql -BN -h $primary -e "set group_replication_consistency='BEFORE_AND_AFTER';
                            INSERT INTO 
                             mysql.backup_group(hostname, state, started_at)
                            SELECT '$hostname', 'RUNNING', now()
                            WHERE NOT EXISTS (SELECT * FROM mysql.backup_group);"
}

removeLock() {
  mysql -BN -h $primary -e "set group_replication_consistency='BEFORE_AND_AFTER';                            delete from mysql.backup_group"
}

takeTheBackup() {
  hostname_with_lock=$(mysql -BN -h $hostname -e "SELECT hostname from mysql.backup_group;")
  if [ "$hostname_with_lock" == "$hostname" ]
  then
    echo "BACKUP is performed on $hostname"
    mysqlbackup  --with-timestamp --backup-dir /backup --user clusteradmin --password=fred  backup
    removeLock
  else
   echo "There is already a backup running on another node"
  fi
}

checkStatus() {
  read candidate readonly applyqueue certqueue < <(mysql -BN -h $hostname -e "select * from sys.gr_member_routing_candidate_status;")
   if [ "$candidate" == "NO" ]
   then
      echo "Member ($hostname) in non primary partition"
      exit 1
   fi
   if [ $applyqueue -ge $QUEUE_TRESHOLD ]
   then
      echo "Member ($hostname) has a large apply queue: $applyqueue"
      exit 2
   fi
}


checkTable
checkView
checkStatus
getTheBackup
takeTheBackup
