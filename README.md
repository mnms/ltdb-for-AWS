# FlashBase

FlashBase is a distributed in-memory DBMS for real-time big data analytics, which is optimized for time-series data and geospatial data. It supports tiered storage to persist data in a fast and secure manner. The high performance of the FlashBase enables you to process streams of data from multiple sources in real-time.

## Source code structure

```bash
├── flashbase 
    ├── bin                                         <-- tsr2-installer.bin
    ├── conf                                        <-- Configurations for hadoop, spark, and redis
        ├── hadoop                                  
        ├── redis                                    
        └── spark
    ├── packages                                    <-- Essenctial packages for installing and running FlashBase 
    ├── tsr2-test
        ├── ddl                                     <-- Data definition language for querying 
        ├── load                                    <-- test data sample for data insertion
        └── json
    └── scripts
        ├── provisioner                             <-- Install essential packages for FlashBase
        └── userdata                                <-- Scripts for running FlashBase, hadoop and spark.                            
```

## Prerequisites

* Redis configuration should be adjusted depending on instance type you launched.
    * Configuration files ; ``redis.properties``, ``redis-master.conf`` and ``redis-slave.conf``
    * All configuration files related to redis are located at ``~/flashbase/conf/redis``
         ```bash
        $ cd ~/flashbase/conf/redis
        ```
    * Recommended
      * The number of processes of redis-server : ``The number of vCPU * 4``
      * Total memory of all redis-servers : Free memory capacity * 80%

## How to Run 

If you want to use FlashBase with default configurations, you just go to ``~/flashbase/scripts/userdata`` and execute ``./run.sh``

```bash
$ cd ~/flashbase/scripts/userdata
$ ./run.sh
```

* You can figure out how to run each of softwares(hadoop, spark and redis) in run.sh
* Or, you can find more instructions at https://github.com/mnms/share. (Supports Korean only) 


## Data Insertion to FlashBase

tsr2-tools can be used for data insertion. Usage for tsr2-tools is 
```
$ cfc 1
$ cd /home/ec2-user/flashbase/tsr2-test
$ tsr2-tools insert -d ./load -s "|" -t ./json/test.json -p 8 -c 1 -i
```

You can also monitor data insertion status with the instruction as below. 
<pre><code>flashbase cli monitor</code></pre>

Inserted data confirmation
```bash
$ flashbase cli 'keys *'
or
$ flashbase cli 'metakeys *'
```

Spark executor is running properly as below, query to inserted data via ``thriftserver beeline``

 ``` bash
$ jps

47648 DataNode
48641 SparkSubmit
49123 CoarseGrainedExecutorBackend
48197 ResourceManager
47400 NameNode
47944 SecondaryNameNode
49513 CoarseGrainedExecutorBackend
49514 CoarseGrainedExecutorBackend
49067 CoarseGrainedExecutorBackend
49515 CoarseGrainedExecutorBackend
49932 CoarseGrainedExecutorBackend
49933 CoarseGrainedExecutorBackend
49934 CoarseGrainedExecutorBackend
50353 CoarseGrainedExecutorBackend
50354 CoarseGrainedExecutorBackend
50356 CoarseGrainedExecutorBackend
48373 NodeManager
49302 CoarseGrainedExecutorBackend
51481 Jps
48986 ExecutorLauncher
 ```

``` bash
$ cd /home/ec2-user/flashbase/tsr2-test/ddl
$ thriftserver beeline -f ./ddl_fb_test_101.sql
```

Results
``` bash
Connecting to jdbc:hive2://localhost:13000
19/08/30 06:10:22 INFO jdbc.Utils: Supplied authorities: localhost:13000
19/08/30 06:10:22 INFO jdbc.Utils: Resolved authority: localhost:13000
19/08/30 06:10:22 INFO jdbc.HiveConnection: Will try to open client transport with JDBC Uri: jdbc:hive2://localhost:13000
Connected to: Spark SQL (version 2.3.1)
Driver: Hive JDBC (version 1.2.1.spark2)
Transaction isolation: TRANSACTION_REPEATABLE_READ
0: jdbc:hive2://localhost:13000> drop table if exists fb_test;
+---------+--+
| Result  |
+---------+--+
+---------+--+
No rows selected (0.479 seconds)
0: jdbc:hive2://localhost:13000> create table if not exists fb_test
0: jdbc:hive2://localhost:13000> (user_id string,
0: jdbc:hive2://localhost:13000> name string,
0: jdbc:hive2://localhost:13000> company string,
0: jdbc:hive2://localhost:13000> country string,
0: jdbc:hive2://localhost:13000> event_date string,
0: jdbc:hive2://localhost:13000> data1 string,
0: jdbc:hive2://localhost:13000> data2 string,
0: jdbc:hive2://localhost:13000> data3 string,
0: jdbc:hive2://localhost:13000> data4 string,
0: jdbc:hive2://localhost:13000> data5 string)
0: jdbc:hive2://localhost:13000> using r2 options (table '101', host 'localhost', port '18101', partitions 'user_id country event_date', mode 'nvkvs', group_size '10', query_result_partition_cnt_limit '40000', query_result_task_row_cnt_limit '10000', query_result_total_row_cnt_limit '100000000');
+---------+--+
| Result  |
+---------+--+
+---------+--+
No rows selected (1.184 seconds)
0: jdbc:hive2://localhost:13000>
Closing: 0: jdbc:hive2://localhost:13000
```

How to query and result.

```bash
$ thriftserver beeline

Connecting to jdbc:hive2://localhost:13000
19/08/30 06:11:35 INFO jdbc.Utils: Supplied authorities: localhost:13000
19/08/30 06:11:35 INFO jdbc.Utils: Resolved authority: localhost:13000
19/08/30 06:11:35 INFO jdbc.HiveConnection: Will try to open client transport with JDBC Uri: jdbc:hive2://localhost:13000
Connected to: Spark SQL (version 2.3.1)
Driver: Hive JDBC (version 1.2.1.spark2)
Transaction isolation: TRANSACTION_REPEATABLE_READ
Beeline version 1.2.1.spark2 by Apache Hive
0: jdbc:hive2://localhost:13000> show tables;
+-----------+------------+--------------+--+
| database  | tableName  | isTemporary  |
+-----------+------------+--------------+--+
| default   | fb_test    | false        |
+-----------+------------+--------------+--+
1 row selected (0.165 seconds)
0: jdbc:hive2://localhost:13000> select count(*) from fb_test;
+-----------+--+
| count(1)  |
+-----------+--+
| 100       |
+-----------+--+
1 row selected (4.177 seconds)
or

select count(*) from fb_test;

or

select event_date, company, count(*) from fb_test  where event_date > '0' group by event_date, company;
```
