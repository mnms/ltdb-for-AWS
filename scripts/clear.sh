#!/bin/bash

# stop thrift-server
thriftserver stop;

# stop hadoop and yarn 
/opt/hadoop/sbin/stop-yarn.sh ;
/opt/hadoop/sbin/stop-dfs.sh ;

# unmount directorys
sudo umount /nvme/data_*

# format block devices partition information
sudo wipefs --all --force /dev/nvme* ;

# kill redis processes still alive 
REDIS_PROCESS=(`ps -ef | grep redis-server | grep -v grep | wc -l`)
if [ ${REDIS_PROCESS} -ne 0 ]; then
        echo "There are still alive redis-process. Aborting them..."
	kill -9 `ps -ef | grep redis-server | grep -v grep | awk '{print $2}'`
fi

# delete data diretory for redis and hadoop
sudo rm -rf /nvme

# delete spark log directory
sudo rm -rf /nvdrive0

# delete all authentication info
sudo rm -rf ~/.ssh/known_hosts
sudo rm -rf /home/ec2-user/.ssh/id_rsa*
