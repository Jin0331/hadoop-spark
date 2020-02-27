#!/bin/bash


# hdfs    ------> hdfs dfs -mkdir -p /spark/share-log?
# jupyter ------> jupyter notebook --allow-rot
# vscode  ------> ./code-server


# master
#docker run -dit -v /home/jinoo/data:/usr/local/etc --name master --network hadoop --hostname=master --ip 10.0.1.2 -p 8989:8989 -p 8888:8888 -p 8081:8081 -p 4040:4040 -p 18080:18080 -p 9870:9870 -p 9000:9000 -p 8088:8088 -p 8042:8042 -p 8085:8080 -p 2122:22 --add-host=master:10.0.1.2 --add-host=slave1:10.0.1.3 --add-host=slave2:10.0.1.4 --add-host=slave3:10.0.1.5 --add-host=slave4:10.0.1.6 --cpuset-cpus=0 -m 35g --memory-swap=40g sempre813/hadoop_spark-master:latest /bin/bash


# slaves
docker run -dit --name slave1 --network hadoop --hostname=slave1 --ip 10.0.1.3 --add-host=master:10.0.1.2 --cpuset-cpus=1-7 -m 40g --memory-swap=42g sempre813/hadoop_spark-master:latest /bin/bash

docker run -dit --name slave2 --network hadoop --hostname=slave2 --ip 10.0.1.4 --add-host=master:10.0.1.2 --cpuset-cpus=8-14 -m 40g --memory-swap=41g sempre813/hadoop_spark-master:latest /bin/bash



