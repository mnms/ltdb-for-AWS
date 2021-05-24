#!/bin/bash

PACKAGE="flashbase"

PACKAGE_HOME="$HOME/$PACKAGE"
TSR2_HOME="$HOME/tsr2"

BASE_CONF="${PACKAGE_HOME}/conf"
THIRDPARTY="${PACKAGE_HOME}/thirdparty"

##################################################################
# Functions
##################################################################
function set-env-vars() {
	cat ${PACKAGE_HOME}/.bashrc_envs > $HOME/.bashrc ;

	. $HOME/.bashrc

	if [[ -z "$SR2_HOME" ]];then
		while [[ -h "$PRG" ]] ; do
			ls=`ls -ld "$PRG"`
			link=`expr "$ls" : '.*-> \(.*\)$'`
			if expr "$link" : '/.*' > /dev/null; then
				PRG="$link"
			else
				PRG=`dirname "$PRG"`/"$link"
			fi
		done
		cd $(dirname $PRG)/..
		export SR2_HOME=`pwd`
		cd -&>/dev/null
	fi
	SR2_CONF=${SR2_CONF:=$SR2_HOME/conf}
}

function set-system-config() {
	cd ${PACKAGE_HOME}
	sudo /bin/su -c "cat .sysctl.conf >> /etc/sysctl.conf"
	sudo sysctl -p

	sudo /bin/su -c "cat .limits.conf >> /etc/security/limits.conf"
	sudo sh -c "ulimit -n 65535"
	sudo sh -c "ulimit -n 131072"

	rm -rf .sysctl.conf .limits.conf

	cd -
}

function set-auth-for-localhost() {
	ssh-keygen -t rsa -N "" -f $HOME/.ssh/id_rsa; cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys;
	ssh-keyscan -t ecdsa 127.0.0.1 >> $HOME/.ssh/known_hosts
	ssh-keyscan -t ecdsa 0.0.0.0 >> $HOME/.ssh/known_hosts
	ssh-keyscan -t ecdsa localhost >> $HOME/.ssh/known_hosts
	chmod og-wx $HOME/.ssh/authorized_keys;
}

function install-ruby() {
	local RUBY_DIR="${THIRDPARTY}/ruby"
	local GEM_DIR="${RUBY_DIR}/gemfile"

	tar -zxvf ruby.tar.gz
	cd ${RUBY_DIR}

	sudo yum install -y git gcc openssl-devel readline-devel zlib-devel

	git clone git://github.com/sstephenson/rbenv.git ~/.rbenv
	mkdir ~/.rbenv/plugins

	git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

	cd ~/.rbenv/plugins/ruby-build/
	sudo ./install.sh && cd ~

	source ~/.bashrc

	rbenv install 2.6.4
	rbenv rehash
	rbenv global 2.6.4

	gem install bundler
	rbenv rehash

	cd ${GEM_DIR}
	bundle install

	cd ${THIRDPARTY} && rm -rf ruby

	cd ${PACKAGE_HOME}
}

function install-mkl() {
	cd ${THIRDPARTY}
	tar xvf l_mkl_2019.4.243.tar
	cd l_mkl_2019.4.243

	cat ./silent.cfg | grep -v EULA > ./silent.cfg.tmp
	echo "ACCEPT_EULA=accept" >> ./silent.cfg.tmp

	mv silent.cfg.tmp silent.cfg

	echo "Start to install MKL"
	sudo ./install.sh --silent ./silent.cfg
	echo "MKL installed"

	cd ${THIRDPARTY} && rm -rf l_mkl_2019.4.243

	cd -
}

function do-deps-install() {
	cd ${THIRDPARTY}

	# install essential packages for FB 
	sudo yum install -y vim ruby unzip boost boost-thread boost-devel python-pip cyrus-sasl-devel gcc-c++ python3 python3-devel
	sudo amazon-linux-extras install -y epel

	pip uninstall cryptography -y --user && sudo yum -y autoremove && pip install --upgrade cryptography --user
	pip install fbctl --user
	pip install --upgrade paramiko --user

	pip3 install numpy pandas dask dask[dataframe] dask[distributed] toolz psutil --user
	pip3 install --user 'fsspec>=0.3.3'
	pip3 install --user dask distributed --upgrade

    # install ruby
    install-ruby

    # install MKL
    install-mkl

	# install hadoop
	local HADOOP_PACKAGE=(`ls | grep hadoop`)
	tar -zxvf $HADOOP_PACKAGE
	local HADOOP_DIR=(`ls | grep hadoop | grep -v -E 'tar|tar.gz|tgz'`)
	sudo mv ${HADOOP_DIR} /opt/

	# install spark
	local SPARK_PACKAGE=(`ls | grep spark`)
	tar -zxvf $SPARK_PACKAGE
	local SPARK_DIR=(`ls | grep spark | grep -v -E 'tar|tar.gz|tgz'`)
	sudo mv ${SPARK_DIR} /opt/

	# install java
	local JAVA_PACKAGE=(`ls | grep jdk`)
	tar -zxvf $JAVA_PACKAGE
	local JAVA_DIR=(`ls | grep jdk | grep -v -E 'tar|tar.gz|tgz'`)
	sudo mv ${JAVA_DIR} /opt/

	# install zeppelin
	local ZEPPELIN_PACKAGE=(`ls | grep zeppelin`)
	tar -zxvf $ZEPPELIN_PACKAGE
	local ZEPPELIN_DIR=(`ls | grep zeppelin | grep -v -E 'tar|tar.gz|tgz'`)
	sudo mv ${ZEPPELIN_DIR} /opt/

	sudo mv /opt/hadoop* /opt/hadoop
	sudo mv /opt/spark* /opt/spark
	sudo mv /opt/zeppelin* /opt/zeppelin

	sudo cp ${BASE_CONF}/hadoop/* /opt/hadoop/etc/hadoop/ ;
	sudo cp ${BASE_CONF}/spark/spark-defaults.conf.template /opt/spark/conf/ ;
	sudo cp ${BASE_CONF}/zeppelin/* /opt/zeppelin/conf/ ;

	sudo chown -R ec2-user:ec2-user /opt/zeppelin/conf/

	cd ${PACKAGE_HOME}
}

function ready-to-deploy() {
	sudo yum -y update;
	set-env-vars;
	set-auth-for-localhost;
	set-system-config;
do-deps-install;
}

# Function Calls
ready-to-deploy
