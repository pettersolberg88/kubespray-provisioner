FROM registry.access.redhat.com/openshift3/apb-base:v3.11.51-2
MAINTAINER Johannes Kanavin

RUN pip install acc_provision
yum install vault
