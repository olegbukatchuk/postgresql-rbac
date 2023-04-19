#!/usr/bin/env bash

. ./pg_envs.sh

getHelp () {
	cat <<- EOF

		Usage: $0 options

		This script import your local dump to local Docker container.

		Example: ./pg_rbac_sql_import.sh -d example_db -f ./sql/dump/example_db.sql

		OPTIONS:

      -h    Show this message
      -d    Database
      -f    Dump file

EOF
}

pgSqlImport () {
  local CMD=$1
	psql --host="$HOST" \
			 --port="$PORT" \
			 --username="$ROOT" \
			 --no-psqlrc \
			 --no-align \
			 --tuples-only \
			 --record-separator="$S" \
			 --quiet \
			 --echo-queries \
			 --command="$CMD" "$DB" \
       < $DUMP
}

while getopts 'hd:f:' OPTION; do
	case $OPTION in
		h) getHelp; exit 1;;
		d) DB=$OPTARG;;
		f) DUMP=$OPTARG;;
	esac
done

if [ -z "$DB" ] || [ -z "$DUMP" ]; then
	getHelp
	exit 1
fi

pgSqlImport
