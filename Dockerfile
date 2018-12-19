FROM registry.access.redhat.com/openshift3/apb-base:v3.11.51-2
MAINTAINER Johannes Kanavin

RUN yum install python-pip
RUN pip install acc_provision
RUN yum install vault
