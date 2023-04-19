#!/bin/sh

set -e

cmd="pgbackrest --stanza=$NOMAD_JOB_NAME stanza-create"
timer="5"

until pg_isready 2>/dev/null; do
  >&2 echo "Postgres is unavailable - sleeping for $timer seconds"
  sleep $timer
done

>&2 echo "Postgres is up - executing command"

exec $cmd

exec "$@"