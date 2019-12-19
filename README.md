## kmu-bigdata/ubuntu-spark 활용

### 수정사항

* python3.7, spark-2.4.4, jupyter install - 19.12.19

- - -

### Docker Swarm init
``docker swarm init --advertise-addr [server IP]``

 * node에서 ``docker swarm join --token [token]``
 
 * token re-load ``docker swarm join-token worker``
 
### Docker network create
``docker network create -d overlay hadoop --attachable``

``docker network ls``

``docker network inspect hadoop`` 

### Master

``docker run -dit -v /home/jinoo/data:/usr/local/etc --name master --network hadoop --hostname=master --ip 10.0.1.2 -p 8888:8888 -p 8081:8081 -p 4040:4040 -p 18080:18080 -p 9870:9870 -p 9000:9000 -p 8088:8088 -p 8042:8042 -p 8085:8080 -p 2122:22 --add-host=master:10.0.1.2 --add-host=slave1:10.0.1.3 --add-host=slave2:10.0.1.4 --add-host=slave3:10.0.1.5 --add-host=slave4:10.0.1.6 --add-host=slave5:10.0.1.7 sempre813/hadoop_spark-master  /bin/bash``

#### HDFS namenode format & Spark standalone 
``$HADOOP_HOME/etc/hadoop/worker`` 수정

``hdfs namenode -format``

``$HADOOP_HOME/sbin/start-dfs.sh ## no yarn start!``

``$SPARK_HOME/conf/slaves`` 수정

``$SPARK_HOME/sbin/start-master.sh``

``$SPARK_HOME/sbin/start-slaves.sh``

### Slaves

``docker run -dit --name slave3 --network hadoop --hostname=slave3 --ip 10.0.1.5 -p 8081:8081 -p 9866:9866 -p 9865:9865 -p 9867:9867 -p 8088:8088 -p 4040:4040 -p 4041:4041 --add-host=master:10.0.1.2 sempre813/hadoop_spark-master /bin/bash``


