FROM openjdk:8-jre-alpine
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
ENV SPARK_UID=${SPARK_UID}
ENV SPARK_GID=${SPARK_GID}
ENV SPARK_USER=${SPARK_USER}
ENV SPARK_GROUP=${SPARK_GROUP}
RUN addgroup -g ${SPARK_GID} -S ${SPARK_GROUP}
RUN adduser -u ${SPARK_UID} -D -S -G ${SPARK_USER} ${SPARK_GROUP}

###########################################
#### ENV VERSIONS
###########################################
ARG SPARK_VERSION=2.1.1
ARG MAJOR_HADOOP_VERSION=2.7
ARG SPARK_HOME=/opt/spark
ENV SPARK_VERSION ${SPARK_VERSION}
ENV MAJOR_HADOOP_VERSION ${MAJOR_HADOOP_VERSION}
ENV SPARK_HOME ${SPARK_HOME}
ENV PYSPARK_PYTHON=python3
LABEL name="SPARK" version=${SPARK_VERSION}

###########################################
#### PYSPARK WITH PY3
#### http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
###########################################
ENV PYTHONHASHSEED=0
ENV PYTHONIOENCODING="UTF-8"
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

###########################################
#### DIRECTORIES
###########################################
RUN mkdir -p ${SPARK_HOME}

###########################################
#### INSTALL PYTHON AND DEPENDENCIES
###########################################
RUN apk add --no-cache libstdc++ lapack-dev python3 bash tar shadow wget python3-dev build-base && \
    apk add --no-cache --virtual=.build-dependencies g++ gfortran musl-dev python3-dev && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    ln -s locale.h /usr/include/xlocale.h && \
    pip install numpy && \
    pip install pandas && \
    pip install pandasql && \
    pip install scipy && \
    pip install scikit-learn && \
    find /usr/lib/python3.*/ -name 'tests' -exec rm -r '{}' + && \
    rm /usr/include/xlocale.h && \
    rm -r /root/.cache && \
    apk del .build-dependencies

###########################################
#### INSTALL SPARK
###########################################
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