#!/usr/bin/env bash

. ./pg_envs.sh

getHelp () {
	cat <<- EOF

		Usage: $0 options

		This script create database.

		Example: ./pg_rbac_create_db.sh -d example_db -s example_db_schema

		OPTIONS:

      -h   Show this message
      -d   Database
      -s   Schema (default: public)

EOF
}

pgExec() {
	local CMD=$1
	psql --host="$HOST" \
			 --port="$PORT" \
			 --username="$ROOT" \
			 $POSTGRES \
			 --no-psqlrc \
			 --no-align \
			 --tuples-only \
			 --record-separator="$S" \
			 --quiet \
			 --echo-queries \
			 --command="$CMD" "$DB"
}

while getopts 'hd:s:' OPTION; do
	case $OPTION in
		h) getHelp; exit 1;;
		d) DB=$OPTARG;;
		s) SCHEMA=$OPTARG;;
	esac
done

if [ -z "$DB" ]; then
	getHelp
	exit 1
fi

pgExec "CREATE DATABASE $DB;"
