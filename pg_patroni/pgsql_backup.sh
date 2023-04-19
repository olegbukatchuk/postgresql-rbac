#!/bin/bash

pg_conteiner=$(docker ps |  grep pgsql | awk {'print$1'}) \
&& docker exec $pg_conteiner pgbackrest --stanza=pgsql-patroni --log-level-console=info --type=$1 backup