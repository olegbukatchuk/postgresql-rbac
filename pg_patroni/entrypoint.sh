#!/bin/sh

rm -rf /etc/pgbackrest/pgbackrest.conf

echo "[global]
repo1-path=/home/postgres/backup/postgres
repo1-retention-full=2
repo1-retention-diff=28
process-max=2
log-level-console=info

[global:archive-push]
compress-level=3

[$NOMAD_JOB_NAME]
pg1-path=/home/postgres/data/" >> /etc/pgbackrest/pgbackrest.conf

/home/postgres/stanza-init.sh &

patroni postgres1.yml
