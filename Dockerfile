FROM amazonlinux:latest

# Maintainer
# ----------
MAINTAINER David Filiatrault <david.filiatrault+docker@gmail.com>
# Credits
# Adapted from payaradocker/payaraserver which was ubuntu based
# Built via docker build -t fireballdwf/amazon-payara:latest .

ENV PKG_VERSION 4.1.1.171
ENV PKG_FILE_NAME payara-$PKG_VERSION.zip
ENV PAYARA_PKG https://s3-eu-west-1.amazonaws.com/payara.fish/Payara+Downloads/Payara+$PKG_VERSION/$PKG_FILE_NAME
ENV GLASSFISH_INSTALL_DIR /opt/payara41/glassfish
ENV APPDOMAIN payaradomain

# add payara user, download payara nightly build and unzip
RUN yum -y update && yum -y install awslogs shadow-utils java-1.8.0-openjdk-headless wget unzip &&  adduser -b /opt -m -s /bin/bash payara && echo payara:payara | chpasswd && cd /opt && wget $PAYARA_PKG && unzip $PKG_FILE_NAME && rm $PKG_FILE_NAME && chown -R payara:payara /opt/payara41* 
ENV JAVA_HOME=/usr/lib/jvm/jre
# Setup AWSLOGS agent per http://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html
COPY awslogs.conf /etc/awslogs
#RUN service awslogs start && chkconfig awslogs on
# RUN  aws configure set plugins.cwlogs cwlogs 


# Default payara ports to expose
EXPOSE 4848 8009 8080 8181

# Set up payara user and the home directory for the user
USER payara

ENV MYSQL_JDBC_PACKAGE mysql-connector-java-5.1.41
RUN wget -O - https://dev.mysql.com/get/Downloads/Connector-J/$MYSQL_JDBC_PACKAGE.tar.gz  | tar -C /tmp -xvzf - $MYSQL_JDBC_PACKAGE/$MYSQL_JDBC_PACKAGE-bin.jar && \
    mv /tmp/$MYSQL_JDBC_PACKAGE/$MYSQL_JDBC_PACKAGE-bin.jar $GLASSFISH_INSTALL_DIR/domains/$APPDOMAIN/lib/databases

WORKDIR $GLASSFISH_INSTALL_DIR/bin

# User: admin / Pass: glassfish
# enable secure admin to access DAS remotely. Note we are using the domain payaradomain
RUN echo "admin;{SSHA256}80e0NeB6XBWXsIPa7pT54D9JZ5DR5hGQV1kN1OAsgJePNXY6Pl0EIw==;asadmin" > $GLASSFISH_INSTALL_DIR/domains/$APPDOMAIN/config/admin-keyfile && \
    echo "AS_ADMIN_PASSWORD=glassfish" > pwdfile &&  \
    echo "export PATH=$PATH:$GLASSFISH_INSTALL_DIR/bin" >> /opt/payara/.bashrc && \
  ./asadmin start-domain $APPDOMAIN && \
  ./asadmin --user admin --passwordfile pwdfile enable-secure-admin && \
  ./asadmin stop-domain $APPDOMAIN
 


