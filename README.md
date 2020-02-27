## kmu-bigdata/ubuntu-spark 활용

### 수정사항

* python3.7, spark-2.4.4, jupyter install - 19.12.19
* nano, findspark - 19.12.26
* vscode & worker change - 19.12.31
* redis adding - 20.01.03
* pyarrow & spark 2.4.5 - 20.02.27

- - -

### Docker Swarm init
``docker swarm init --advertise-addr [server IP]``

 * node에서 ``docker swarm join --token [token]``
 
 * token re-load ``docker swarm join-token worker``
 
### Docker network create

``docker network create -d overlay hadoop --attachable``

``docker network ls``

``docker network inspect hadoop`` 


#### HDFS namenode format & Spark standalone 

``hdfs namenode -format``

``$HADOOP_HOME/sbin/start-dfs.sh ## no yarn start!``

``$SPARK_HOME/sbin/start-master.sh & SPARK_HOME/sbin/start-slaves.sh``
