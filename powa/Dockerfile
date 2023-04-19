FROM centos:centos7

LABEL maintainer="Oleg Bukatchuk"

RUN yum -y update && \
    yum -y install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7Server-x86_64/pgdg-centos10-10-2.noarch.rpm && \
    yum -y install python-pip python-psycopg2 && \
    yum -y install powa_10-web && \
    yum -y clean all

COPY powa-origin.conf /etc/powa-web.conf

EXPOSE 8888

CMD ["powa-web"]
