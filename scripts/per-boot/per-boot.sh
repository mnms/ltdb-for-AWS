#!/bin/sh

echo boot at `date` >> /tmp/per-boot.txt

USER="ec2-user"
USER_HOME="/home/${USER}"

. ${USER_HOME}/.bashrc

sudo umount /dev/nvme*n* ;
sudo wipefs --all --force /dev/nvme* ;
sudo rm -rf ${SR2_DATA_ROOT}


DIR_PREFIX=
DEVICE_COUNT=(`lsblk | grep nvme | wc -l`)
MOUNT_DIR=(`lsblk | grep nvme | awk '{print $7}' | grep -v "" | wc -l`)

AUTH=(`ls ${USER_HOME}/.ssh/ | grep id_rsa.pub`)

if [[ ${AUTH} == "" ]]; then
    ssh-keygen -t rsa -N "" -f ${USER_HOME}/.ssh/id_rsa; cat ${USER_HOME}/.ssh/id_rsa.pub >> ${USER_HOME}/.ssh/authorized_keys;

    checker=(`cat ${USER_HOME}/.ssh/know_hosts | grep 127.0.0.1`)
    if [[ ${checker} == "" ]]; then
        ssh-keyscan -t ecdsa 127.0.0.1 >> ${USER_HOME}/.ssh/known_hosts
    fi

    checker=(`cat ${USER_HOME}/.ssh/know_hosts | grep 0.0.0.0`)
    if [[ ${checker} == "" ]]; then
        ssh-keyscan -t ecdsa 0.0.0.0   >> ${USER_HOME}/.ssh/known_hosts
    fi

    checker=(`cat ${USER_HOME}/.ssh/know_hosts | grep localhost`)
    if [[ ${checker} == "" ]]; then
        ssh-keyscan -t ecdsa localhost >> ${USER_HOME}/.ssh/known_hosts
    fi

    sudo chmod og-wx ${USER_HOME}/.ssh/authorized_keys;
    sudo chown -R ${USER}:${USER} ${USER_HOME}/.ssh/*
else
    echo "Authorization for localhost done already"
fi

for ((num=1; num<=${DEVICE_COUNT}; num++));
do
        if [[ ${num} -lt 10 ]]; then
            DIR_PREFIX=${SR2_REDIS_DATA}0
        else
		    DIR_PREFIX=${SR2_REDIS_DATA}
        fi
        sudo mkdir -p ${DIR_PREFIX}${num}
done

if [[ ${MOUNT_DIR} -ne ${DEVICE_COUNT} ]] ; then
    echo "Storage device not mounted yet" >> /tmp/per-boot.txt

        DISK_NUM=1;

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
        sudo chown -R ${USER}:${USER} ${SR2_DATA_ROOT}
else
    echo "Storage device already mounted"
fi

for ((num=1; num<=${DEVICE_COUNT}; num++));
do
        if [[ $num -lt 10 ]]; then
                DIR_PREFIX=${SR2_REDIS_DATA}0
        else
                DIR_PREFIX=${SR2_REDIS_DATA}
        fi

        sudo mkdir -p ${DIR_PREFIX}${num}/hadoop/data
        sudo mkdir -p ${DIR_PREFIX}${num}/hadoop/tmp
        sudo mkdir -p ${DIR_PREFIX}${num}/yarn

        if [[ ${num} -eq 1 ]]; then
            sudo mkdir ${DIR_PREFIX}${num}/hadoop/name
            sudo mkdir ${DIR_PREFIX}${num}/yarn/logs
        fi
done

${HADOOP_HOME}/bin/hdfs namenode -format -force ;
sudo chown -R ${USER}:${USER} ${SR2_DATA_ROOT}

# Get latest fbctl version everytime ec2 instantiated.
pip install fbctl --user --upgrade

# turnoff swap
swapoff -a
