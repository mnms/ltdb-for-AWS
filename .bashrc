# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:

# User specific aliases and functions

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.

# JAVA
export JAVA_HOME=/opt/jdk1.8.0_201
export JRE_HOME=/opt/jdk1.8.0_201/jre
export PATH=$PATH:/opt/jdk1.8.0_201/bin:/opt/jdk1.8.0_201/jre/bin

###### FlashBase ######
alias cfc='source ~/.use_cluster'
alias fb='flashbase'
export FBPATH=$HOME/.flashbase
export PATH="$PATH:$HOME/.rvm/bin"

export RUBY_HOME=${HOME}/.rbenv
export KAFKA_HOME=$HOME/kafka

export LS_COLORS="di=00;36"

#STLOGIC
export PATH=${PATH}:${RUBY_HOME}/bin

export HADOOP_HOME=/home/nvkvs/stlogic/hadoop-2.7.3
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HOME/sbin

export SPARK_HOME=/home/nvkvs/stlogic/spark-2.2.0-bin-hadoop2.7
export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

export HIVE_HOME=/home/nvkvs/stlogic/apache-hive-1.2.1-bin
export PATH=$PATH:$HIVE_HOME/bin

export ZEPPELIN_HOME=/home/nvkvs/stlogic/zeppelin-0.7.3-bin-all
export PATH=$PATH:$ZEPPELIN_HOME/bin

export LIVY_HOME=/home/nvkvs/stlogic/livy-0.5.0-incubating-bin
export PATH=$PATH:$LIVY_HOME/bin

export LIVY_HOME=~/stlogic/livy-0.5.0-incubating-bin/
export HTTP_HOME=~/stlogic/fb-gis-http/

# INTEL MKL enviroment variables for ($MKL_ROOT, can be checked with the value export | grep MKL)
source /opt/intel/mkl/bin/mklvars.sh intel64
