#!/bin/bash

REDIS_CMD="flashbase"
PACKAGE="flashbase"

PACKAGE_HOME="$HOME/$PACKAGE"
BASE_CONF="$PACKAGE_HOME/conf"
TSR2_HOME="$HOME/tsr2"

##################################################################
# Functions
##################################################################
function set-env-vars() {
    . $HOME/.bashrc
    . $BASE_CONF/redis/redis.properties
}

function set-auth-for-localhost() {
    local authorized=(`ls ~/.ssh/ | grep id_rsa.pub`)

    if [[ ${authorized} == "" ]]; then
	    ssh-keygen -t rsa -N "" -f $HOME/.ssh/id_rsa; cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys;
	    ssh-keyscan -t ecdsa 127.0.0.1 >> $HOME/.ssh/known_hosts
	    ssh-keyscan -t ecdsa localhost >> $HOME/.ssh/known_hosts
	    chmod og-wx $HOME/.ssh/authorized_keys;
    else
        echo "Authorization for localhost done already"
    fi
}

function do-disk-mount() {
    DEVICE_COUNT=(`lsblk | grep nvme | wc -l`)
    MOUNT_DIR=(`lsblk | grep nvme | awk '{print $7}' | grep -v "" | wc -l`)

    if [[ ${MOUNT_DIR} -ne ${DEVICE_COUNT} ]] ; then
        echo "Storage device not mounted yet"

	    local DISK_NUM=1;

	    echo ">>> DISK PARTITIONING START !!!"

	    for id in $(lsblk | grep nvme | awk '{print $1}');
	    do
	    	echo -e "o\nn\np\n1\n\n\nw" | sudo fdisk /dev/$id;
	    	sudo mkfs -t ext4 /dev/$id;

	    	if [ $DISK_NUM -lt 10 ]; then
	    		DIR_PREFIX=${SR2_REDIS_DATA}0
	    	else
	    		DIR_PREFIX=${SR2_REDIS_DATA}
	    	fi

	    	sudo mount /dev/${id} ${DIR_PREFIX}${DISK_NUM};
	    	((DISK_NUM++))
	    done;
	    sudo chown -R $USER:$USER /nvme
    else
        echo "Storage device already mounted"
    fi
}

function do-make-dirs() {
	sudo umount /dev/nvme*n* ;
	sudo wipefs --all --force /dev/nvme* ;

	sudo rm -rf /nvme

	cp ${BASE_CONF}/redis/redis.properties ${SR2_CONF}
	cp ${BASE_CONF}/redis/redis-* ${SR2_CONF}

	. ${SR2_CONF}/redis.properties

	DISK_COUNT=${SSD_COUNT:=$SSD_COUNT}

	local DIR_PREFIX

	for ((num=1; num<=$DISK_COUNT; num++));
	do
		if [ $num -lt 10 ]; then
			DIR_PREFIX=${SR2_REDIS_DATA}0
		else
			DIR_PREFIX=${SR2_REDIS_DATA}
		fi
		sudo mkdir -p $DIR_PREFIX$num
	done
	do-disk-mount
}

function set-env-for-hadoop() {
    local DIR_PREFIX
	for ((num=1; num<=$DISK_COUNT; num++));
	do
		if [ $num -lt 10 ]; then
			DIR_PREFIX=${SR2_REDIS_DATA}0
		else
			DIR_PREFIX=${SR2_REDIS_DATA}
		fi

		sudo mkdir -p $DIR_PREFIX$num/hadoop/data
		sudo mkdir -p $DIR_PREFIX$num/hadoop/tmp
		sudo mkdir -p $DIR_PREFIX$num/yarn

		if [ $num -eq 1 ]; then
			sudo mkdir $DIR_PREFIX$num/hadoop/name
			sudo mkdir $DIR_PREFIX$num/yarn/logs
		fi
	done

	sudo chown -R $USER:$USER /nvme

	cp ${BASE_CONF}/hadoop/* /opt/hadoop/etc/hadoop/ ;
	hdfs namenode -format -force ;
}

function set-env-for-spark() {
    cp ${BASE_CONF}/spark/spark-defaults.conf.template /opt/spark/conf
}

swapoff -a
set-env-vars
set-auth-for-localhost
do-make-dirs
set-env-for-hadoop
set-env-for-spark
