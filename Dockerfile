FROM amazonlinux:latest
# TODO: Consider moving to payara/server-full
# Maintainer
# ----------
MAINTAINER David Filiatrault <david.filiatrault+docker@gmail.com>
# Credits
# Adapted from payaradocker/payaraserver which was ubuntu based
# Built via docker build -t fireballdwf/amazon-payara:latest .

ENV PKG_VERSION 4.1.2.173
#ENV PKG_VERSION 4.1.1.164
ENV PKG_FILE_NAME payara-$PKG_VERSION.zip
ENV PAYARA_PKG https://s3-eu-west-1.amazonaws.com/payara.fish/Payara+Downloads/Payara+$PKG_VERSION/$PKG_FILE_NAME
ENV GLASSFISH_INSTALL_DIR /opt/payara41/glassfish
ENV APPDOMAIN payaradomain
ENV LANG en_US.UTF-8  

# add payara user, download payara nightly build and unzip
RUN yum -y update && yum -y install shadow-utils java-1.8.0-openjdk-headless wget unzip aws-cli openssh-clients && \
adduser -b /opt -m -s /bin/bash payara && echo payara:payara | chpasswd && cd /opt && mkdir /opt/payara/.walletron && chown payara /opt/payara/.walletron && \
wget $PAYARA_PKG && unzip $PKG_FILE_NAME && rm $PKG_FILE_NAME && chown -R payara:payara /opt/payara41* 
ENV JAVA_HOME=/usr/lib/jvm
ENV JAVA_SECURITY=$JAVA_HOME/jre/lib/security


# Default payara ports to expose
EXPOSE 4848 8080 8181

# Set up payara user and the home directory for the user
USER payara

ENV MYSQL_JDBC_PACKAGE mysql-connector-java-5.1.44
RUN wget -O - https://dev.mysql.com/get/Downloads/Connector-J/$MYSQL_JDBC_PACKAGE.tar.gz  | tar -C /tmp -xvzf - $MYSQL_JDBC_PACKAGE/$MYSQL_JDBC_PACKAGE-bin.jar && \
    mv /tmp/$MYSQL_JDBC_PACKAGE/$MYSQL_JDBC_PACKAGE-bin.jar $GLASSFISH_INSTALL_DIR/domains/$APPDOMAIN/lib 

USER 0
RUN rm -rf  /tmp/* && yum -y remove wget unzip  && yum -y clean all
USER payara

WORKDIR $GLASSFISH_INSTALL_DIR/bin

# User: admin / Pass: glassfish
# enable secure admin to access DAS remotely. Note we are using the domain payaradomain
RUN echo "admin;{SSHA256}80e0NeB6XBWXsIPa7pT54D9JZ5DR5hGQV1kN1OAsgJePNXY6Pl0EIw==;asadmin" > $GLASSFISH_INSTALL_DIR/domains/$APPDOMAIN/config/admin-keyfile && \
    echo "AS_ADMIN_PASSWORD=glassfish" > pwdfile &&  \
    echo "export PATH=$PATH:$GLASSFISH_INSTALL_DIR/bin" >> /opt/payara/.bashrc && \
  ./asadmin start-domain $APPDOMAIN && \
  ./asadmin --user admin --passwordfile pwdfile enable-secure-admin && \
  ./asadmin stop-domain $APPDOMAIN
 


