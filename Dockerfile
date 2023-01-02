FROM registry.access.redhat.com/ubi8/ubi:latest


RUN yum -y update && \
  yum -y install python3-pip && \
  pip3 install --upgrade pip && \
  pip3 install 'ansible==2.9.22'

RUN yum repolist all


