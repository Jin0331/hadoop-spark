FROM kmubigdata/ubuntu-hadoop
MAINTAINER sempre813

USER root

# apt-install
RUN apt-get update \
   && apt-get install -y nano scala python software-properties-common 
RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update && apt-get install -y build-essential libpq-dev libssl-dev openssl libffi-dev zlib1g-dev \
    && apt-get update && apt-get install -y python3-pip python3.7-dev python3.7 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2
                          


# jupyter notebook or lab install
RUN pip3 install jupyter && pip3 install jupyterlab && jupyter notebook --generate-config \
    && sed -i "s/^#c.NotebookApp.ip = 'localhost'/c.NotebookApp.ip='*'/" ~/.jupyter/jupyter_notebook_config.py \
    && sed -i "s/^#c.NotebookApp.open_browser = True/c.NotebookApp.open_browser = False/" ~/.jupyter/jupyter_notebook_config.py \
    && sed -i "s/^#c.NotebookApp.allow_root = False/c.NotebookApp.allow_root = True/" ~/.jupyter/jupyter_notebook_config.py \
    && pip3 install jupyterthemes \
    && jt -t monokai -f anka -fs 12 -nf anka -tf anka -dfs 11 -tfs 12 -ofs 11 -T -N -cellw 85% -kl

# vscode
RUN wget https://github.com/cdr/code-server/releases/download/2.1692-vsc1.39.2/code-server2.1692-vsc1.39.2-linux-x86_64.tar.gz \
    && tar xf code-server2.1692-vsc1.39.2-linux-x86_64.tar.gz \
    && mv code-server2.1692-vsc1.39.2-linux-x86_64 vscode \
    && rm -rf code-server2.1692-vsc1.39.2-linux-x86_64.tar.gz

EXPOSE 8989

# spark 2.4.5 without Hadoop
RUN wget https://archive.apache.org/dist/spark/spark-2.4.5/spark-2.4.5-bin-without-hadoop.tgz \
    && tar -xvzf spark-2.4.5-bin-without-hadoop.tgz -C /usr/local \
    && cd /usr/local && ln -s ./spark-2.4.5-bin-without-hadoop spark \
    && rm -f /spark-2.4.5-bin-without-hadoop.tgz

# ENV hadoop
ENV HADOOP_COMMON_HOME=/usr/local/hadoop \
    HADOOP_HDFS_HOME=/usr/local/hadoop \
    HADOOP_MAPRED_HOME=/usr/local/hadoop \
    HADOOP_YARN_HOME=/usr/local/hadoop \
    HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop \
    YARN_CONF_DIR=/usr/local/hadoop/etc/hadoop

ENV LD_LIBRARY_PATH=/usr/local/hadoop/lib/native/:$LD_LIBRARY_PATH

# ENV spark
ENV SPARK_HOME /usr/local/spark
ENV PATH $PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

## install findspark
RUN pip3 install findspark pyarrow pandas

## spark-env.sh config
RUN cp $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh \
    && echo SPARK_WORKER_CORES=7 >> $SPARK_HOME/conf/spark-env.sh \
    && echo SPARK_WORKER_MEMORY=25G >> $SPARK_HOME/conf/spark-env.sh \
    && echo ARROW_PRE_0_15_IPC_FORMAT=1 >> $SPARK_HOME/conf/spark-env.sh \
    && echo export SPARK_DIST_CLASSPATH=$(/usr/local/hadoop/bin/hadoop classpath) >> $SPARK_HOME/conf/spark-env.sh \
    && echo export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop >> $SPARK_HOME/conf/spark-env.sh \
    && echo export SPARK_CLASSPATH=$SPARK_HOME/jars >> $SPARK_HOME/conf/spark-env.sh \
    && echo export JAVA_HOME=/usr/java/default >> $SPARK_HOME/conf/spark-env.sh \
    && echo export PYSPARK_PYTHON=/usr/bin/python3 >> $SPARK_HOME/conf/spark-env.sh \
    && echo export PYSPARK_DRIVER_PYTHON=/usr/bin/python3 >> $SPARK_HOME/conf/spark-env.sh

## spark-defaults config & slaves
RUN mkdir /tmp/spark-events \
    && $SPARK_HOME/sbin/start-history-server.sh

ADD workers $HADOOP_HOME/etc/hadoop/workers
RUN cp $HADOOP_HOME/etc/hadoop/workers $SPARK_HOME/conf/slaves


#COPY .py files
COPY hadoop_spark_slaves.py /root/hadoop_spark_slaves.py
COPY hdfsupload.py /root/hdfsupload.py

RUN chown root.root /root/hadoop_spark_slaves.py \
    && chmod 700 /root/hadoop_spark_slaves.py \
    && chown root.root /root/hdfsupload.py \
    && chmod 700 /root/hdfsupload.py

#COPY scala JAR file
COPY scalaudf_2.11-0.1.jar /usr/local/spark/jars/scalaudf_2.11-0.1.jar

RUN chown root.root /usr/local/spark/jars/scalaudf_2.11-0.1.jar \
    && chmod 700 /usr/local/spark/jars/scalaudf_2.11-0.1.jar

# Spark Web UI, History Server Port
EXPOSE 8080 18080
EXPOSE 7077

# diver_port
EXPOSE 9898 9797

#install sbt for SCALA
RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list \
 && curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add \
 && apt-get update && apt-get -y install sbt


#RUN apt-get install apt-transport-https \
#    && echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list \
#    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 \
#    && apt-get update && apt-get -y install sbt
