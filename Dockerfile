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
ENV SPARK_USER=${SPARK_USER}
ENV SPARK_GROUP=${SPARK_GROUP}
ENV SPARK_UID=${SPARK_UID}
ENV SPARK_GID=${SPARK_GID}
RUN addgroup -g ${SPARK_GID} -S ${SPARK_GROUP} && \
    adduser -u ${SPARK_UID} -D -S -G ${SPARK_USER} ${SPARK_GROUP}

###########################################
#### ENV VERSIONS
###########################################
ARG SPARK_VERSION=2.1.1
ARG MAJOR_HADOOP_VERSION=2.7
ARG SPARK_HOME=/opt/spark
ENV SPARK_VERSION ${SPARK_VERSION}
ENV MAJOR_HADOOP_VERSION ${MAJOR_HADOOP_VERSION}
ENV SPARK_HOME ${SPARK_HOME}
ENV PYTHON_ALPINE_VERSION="3.5.2-r9"
ENV PYSPARK_PYTHON=/usr/bin/python3
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
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.5/main' >> /etc/apk/repositories && \
    apk add --update --no-cache \
    'python3=='${PYTHON_ALPINE_VERSION} libstdc++ lapack-dev \
    bash tar shadow wget build-base && \
    apk add --no-cache --virtual=.build-dependencies g++ gfortran musl-dev 'python3-dev=='${PYTHON_ALPINE_VERSION} && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    ln -s locale.h /usr/include/xlocale.h && \
    /usr/bin/python3 --version && \
    /usr/bin/pip install numpy pandas pandasql scipy scikit-learn && \
    find /usr/lib/python3.*/ -name 'tests' -exec rm -r '{}' + && \
    rm /usr/include/xlocale.h && \
    rm -r /root/.cache && \
    apk del .build-dependencies

###########################################
#### INSTALL SPARK
###########################################
RUN wget http://d3kbcqa49mib13.cloudfront.net/spark-${SPARK_VERSION}-bin-hadoop${MAJOR_HADOOP_VERSION}.tgz && \
    tar -xvf spark-${SPARK_VERSION}-bin-hadoop${MAJOR_HADOOP_VERSION}.tgz -C ${SPARK_HOME} --strip=1 && \
    rm -rf spark-${SPARK_VERSION}-bin-hadoop${MAJOR_HADOOP_VERSION}.tgz && \
    chown -R ${SPARK_USER}:${SPARK_GROUP} ${SPARK_HOME} && \
    chmod -R g+rwx ${SPARK_HOME}

##########################################
### PORTS
##########################################
EXPOSE 7077 4040 8080

##########################################
### ENTRYPOINT
##########################################
USER ${SPARK_USER}
WORKDIR ${SPARK_HOME}
CMD ${SPARK_HOME}/bin/spark-shell