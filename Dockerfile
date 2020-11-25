FROM kmubigdata/ubuntu-hadoop
MAINTAINER sempre813

USER root

# scala, r install
ARG R_VERSION
ARG BUILD_DATE
ARG CRAN
ENV BUILD_DATE ${BUILD_DATE:-2020-04-24}
ENV R_VERSION=${R_VERSION:-3.6.3} \
    CRAN=${CRAN:-https://cran.rstudio.com} \ 
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    TERM=xterm
  

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    file \
    fonts-texgyre \
    g++ \
    gfortran \
    gsfonts \
    libblas-dev \
    libbz2-1.0 \
    libcurl4 \
    libicu63 \
    libjpeg62-turbo \
    libopenblas-dev \
    libpangocairo-1.0-0 \
    libpcre3 \
    libpng16-16 \
    libreadline7 \
    libtiff5 \
    liblzma5 \
    locales \
    make \
    unzip \
    zip \
    zlib1g \
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen en_US.utf8 \
  && /usr/sbin/update-locale LANG=en_US.UTF-8 \
  && BUILDDEPS="curl \
    default-jdk \
    libbz2-dev \
    libcairo2-dev \
    libcurl4-openssl-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libicu-dev \
    libpcre3-dev \
    libpng-dev \
    libreadline-dev \
    libtiff5-dev \
    liblzma-dev \
    libx11-dev \
    libxt-dev \
    perl \
    tcl8.6-dev \
    tk8.6-dev \
    texinfo \
    texlive-extra-utils \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-recommended \
    x11proto-core-dev \
    xauth \
    xfonts-base \
    xvfb \
    zlib1g-dev" \
  && apt-get install -y --no-install-recommends $BUILDDEPS \
  && cd tmp/ \
  ## Download source code
  && curl -O https://cran.r-project.org/src/base/R-3/R-${R_VERSION}.tar.gz \
  ## Extract source code
  && tar -xf R-${R_VERSION}.tar.gz \
  && cd R-${R_VERSION} \
  ## Set compiler flags
  && R_PAPERSIZE=letter \
    R_BATCHSAVE="--no-save --no-restore" \
    R_BROWSER=xdg-open \
    PAGER=/usr/bin/pager \
    PERL=/usr/bin/perl \
    R_UNZIPCMD=/usr/bin/unzip \
    R_ZIPCMD=/usr/bin/zip \
    R_PRINTCMD=/usr/bin/lpr \
    LIBnn=lib \
    AWK=/usr/bin/awk \
    CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
    CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
  ## Configure options
  ./configure --enable-R-shlib \
               --enable-memory-profiling \
               --with-readline \
               --with-blas \
               --with-tcltk \
               --disable-nls \
               --with-recommended-packages \
  ## Build and install
  && make \
  && make install \
  ## Add a library directory (for user-installed packages)
  && mkdir -p /usr/local/lib/R/site-library \
  && chown root:staff /usr/local/lib/R/site-library \
  && chmod g+ws /usr/local/lib/R/site-library \
  ## Fix library path
  && sed -i '/^R_LIBS_USER=.*$/d' /usr/local/lib/R/etc/Renviron \
  && echo "R_LIBS_USER=\${R_LIBS_USER-'/usr/local/lib/R/site-library'}" >> /usr/local/lib/R/etc/Renviron \
  && echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron \
  ## Set configured CRAN mirror
  && if [ -z "$BUILD_DATE" ]; then MRAN=$CRAN; \
   else MRAN=https://mran.microsoft.com/snapshot/${BUILD_DATE}; fi \
   && echo MRAN=$MRAN >> /etc/environment \
  && echo "options(repos = c(CRAN='$MRAN'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site \
  ## Use littler installation scripts
  && Rscript -e "install.packages(c('littler', 'docopt'), repo = '$CRAN')" \
  && ln -s /usr/local/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
  && ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
  && ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r \
  ## Clean up from R source install
  && cd / \
  && rm -rf /tmp/* \
  && apt-get remove --purge -y $BUILDDEPS \
  && apt-get autoremove -y \
  && apt-get autoclean -y \
  && rm -rf /var/lib/apt/lists/*


# python 3.7 install
RUN apt-get update \
   && apt-get install -y nano python software-properties-common 

RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update && apt-get install -y build-essential libpq-dev libssl-dev openssl libffi-dev zlib1g-dev \
    && apt-get update && apt-get install -y python3-pip python3.7-dev python3.7 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2
                          
# jupyter notebook or lab install
RUN pip3 install jupyter && jupyter notebook --generate-config \
    && sed -i "s/^#c.NotebookApp.ip = 'localhost'/c.NotebookApp.ip='*'/" ~/.jupyter/jupyter_notebook_config.py \
    && sed -i "s/^#c.NotebookApp.open_browser = True/c.NotebookApp.open_browser = False/" ~/.jupyter/jupyter_notebook_config.py \
    && sed -i "s/^#c.NotebookApp.allow_root = False/c.NotebookApp.allow_root = True/" ~/.jupyter/jupyter_notebook_config.py \
    && pip3 install jupyterthemes \
    && jt -t monokai -f anka -fs 12 -nf anka -tf anka -dfs 11 -tfs 12 -ofs 11 -T -N -cellw 85% -kl
RUN pip3 install jupyterlab

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

##install sbt for SCALA
#RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list \
# && curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add \
# && apt-get update && apt-get -y install sbt
#RUN apt-get install apt-transport-https \
#    && echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list \
#    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 \
#    && apt-get update && apt-get -y install sbt
