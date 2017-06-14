FROM python:3.5
MAINTAINER Robson Júnior <bsao@cerebello.co> (@bsao)

###########################################
#### Users with other locales
###########################################
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ARG SPARK_USER=spark
ARG SPARK_GROUP=spark
ARG SPARK_UID=7000
ARG SPARK_GID=7000
ENV SPARK_USER=${SPARK_USER}
ENV SPARK_GROUP=${SPARK_GROUP}
RUN groupadd --gid=${SPARK_GID} ${SPARK_GROUP}
RUN useradd --uid=${SPARK_UID} --gid=${SPARK_GID} --no-create-home ${SPARK_USER}

###########################################
#### ENV VERSIONS
###########################################
ARG JAVA_MAJOR_VERSION=8
ARG SPARK_VERSION=2.1.1
ARG MAJOR_HADOOP_VERSION=2.7
ARG SPARK_HOME=/opt/spark
ENV SPARK_VERSION ${SPARK_VERSION}
ENV MAJOR_HADOOP_VERSION ${MAJOR_HADOOP_VERSION}
ENV SPARK_HOME ${SPARK_HOME}
ENV PYSPARK_PYTHON=python3
ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_MAJOR_VERSION}-oracle
LABEL name="SPARK" version=${SPARK_VERSION}

###########################################
#### PYSPARK WITH PY3
#### http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
###########################################
ENV PYTHONHASHSEED=0
ENV PYTHONIOENCODING="UTF-8"
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

###########################################
#### INSTALL JAVA AND ESSENTIAL PKGS
###########################################
RUN \
  echo oracle-java${JAVA_MAJOR_VERSION}-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | \
    tee /etc/apt/sources.list.d/webupd8team-java.list && \
  echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | \
    tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y oracle-java${JAVA_MAJOR_VERSION}-installer oracle-java${JAVA_MAJOR_VERSION}-set-default && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk${JAVA_MAJOR_VERSION}-installer

###########################################
#### INSTALL PIP
###########################################
RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm -rf get-pip.py

###########################################
#### INSTALL SPARK
###########################################
RUN mkdir -p ${SPARK_HOME}
RUN wget http://d3kbcqa49mib13.cloudfront.net/spark-${SPARK_VERSION}-bin-hadoop${MAJOR_HADOOP_VERSION}.tgz && \
    tar -xvf spark-${SPARK_VERSION}-bin-hadoop${MAJOR_HADOOP_VERSION}.tgz -C ${SPARK_HOME} --strip=1 && \
    rm -rf spark-${SPARK_VERSION}-bin-hadoop${MAJOR_HADOOP_VERSION}.tgz
RUN chown -R ${SPARK_USER}:${SPARK_GROUP} ${SPARK_HOME}
RUN chmod -R g+rwx ${SPARK_HOME}

##########################################
### PORTS
##########################################
EXPOSE 7077
EXPOSE 4040
EXPOSE 8080

##########################################
### ENTRYPOINT
##########################################
USER ${SPARK_USER}
WORKDIR ${SPARK_HOME}
CMD ${SPARK_HOME}/bin/spark-shell