FROM kmubigdata/ubuntu-hadoop
MAINTAINER sempre813

USER root

# scala
RUN apt-get update
RUN apt-get install -y scala

# python
RUN apt-get install -y python

# python3.7:latest install 
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt-get update && apt-get install -y build-essential libpq-dev libssl-dev openssl libffi-dev zlib1g-dev
RUN apt-get update && apt-get install -y python3-pip python3.7-dev
RUN apt-get update && apt-get install -y python3.7
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2

# jupyter notebook install
RUN pip3 install jupyter
RUN jupyter notebook --generate-config
RUN sed -i "s/^#c.NotebookApp.ip = 'localhost'/c.NotebookApp.ip='*'/" ~/.jupyter/jupyter_notebook_config.py
RUN sed -i "s/^#c.NotebookApp.open_browser = True/c.NotebookApp.open_browser = False/" ~/.jupyter/jupyter_notebook_config.py
RUN sed -i "s/^#c.NotebookApp.allow_root = False/c.NotebookApp.allow_root = True/" ~/.jupyter/jupyter_notebook_config.py

# spark 2.4.4 without Hadoop
RUN wget https://archive.apache.org/dist/spark/spark-2.4.4/spark-2.4.4-bin-without-hadoop.tgz
RUN tar -xvzf spark-2.4.4-bin-without-hadoop.tgz -C /usr/local
RUN cd /usr/local && ln -s ./spark-2.4.4-bin-without-hadoop spark
RUN rm -f /spark-2.4.4-bin-without-hadoop.tgz

# ENV hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV LD_LIBRARY_PATH=/usr/local/hadoop/lib/native/:$LD_LIBRARY_PATH

# ENV spark
ENV SPARK_HOME /usr/local/spark
ENV PATH $PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

## spark-env.sh config
RUN cp $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh
RUN echo SPARK_WORKER_CORES=2 >> $SPARK_HOME/conf/spark-env.sh
RUN echo SPARK_WORKER_MEMORY=14G >> $SPARK_HOME/conf/spark-env.sh
RUN echo export SPARK_DIST_CLASSPATH=$(/usr/local/hadoop/bin/hadoop classpath) >> $SPARK_HOME/conf/spark-env.sh
RUN echo export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop >> $SPARK_HOME/conf/spark-env.sh
RUN echo export SPARK_CLASSPATH=$SPARK_HOME/jars >> $SPARK_HOME/conf/spark-env.sh
RUN echo export JAVA_HOME=/usr/java/default >> $SPARK_HOME/conf/spark-env.sh
RUN echo export PYSPARK_PYTHON=/usr/bin/python3 >> $SPARK_HOME/conf/spark-env.sh
RUN ehco export PYSPARK_DRIVER_PYTHON=/usr/bin/python3 >> $SPARK_HOME/conf/spark-env.sh

## spark-defaults config
ADD spark-defaults.conf $SPARK_HOME/conf/spark-defaults.conf
RUN cp $HADOOP_HOME/etc/hadoop/workers $SPARK_HOME/conf/slaves

COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh
RUN chmod +x /usr/local/spark/run-sparkshell.sh

# Spark Web UI, History Server Port
EXPOSE 8080 18080

EXPOSE 7077

#install sbt
RUN apt-get install apt-transport-https
RUN echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
RUN apt-get update
RUN apt-get -y install sbt


ENTRYPOINT ["/etc/bootstrap.sh"]
