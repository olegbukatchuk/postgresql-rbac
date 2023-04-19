#!/usr/bin/env bash

. ./pg_envs.sh

getHelp () {
	cat <<- EOF

		Usage: $0 options

		This script changes ownership for all tables, views, sequences and functions in
		a database schema and also owner schema itself.

		Example: ./pg_rbac_set_owner.sh -d example_db -o example_db_admin -s example_db_schema

		OPTIONS:

        -h    Show this message
        -d    Database
        -o    New owner
        -s    Schema (default: public)

EOF
}

pgExec () {
	local CMD=$1
	psql --host="$HOST" \
			 --port="$PORT" \
			 --username="$ROOT" \
			 --no-psqlrc \
			 --no-align \
			 --tuples-only \
			 --record-separator="$S" \
			 --quiet \
			 --command="$CMD" "$DB"
}

pgExecEcho () {
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
			 --command="$CMD" "$DB"
}

while getopts 'hd:o:s:' OPTION; do
	case $OPTION in
		h) getHelp; exit 1;;
		d) DB=$OPTARG;;
		o) OWNER=$OPTARG;;
		s) SCHEMA=$OPTARG;;
	esac
done

if [ -z "$DB" ] || [ -z "$OWNER" ]; then
	getHelp
	exit 1
fi

pgExecEcho "ALTER SCHEMA \"$SCHEMA\" OWNER TO \"$OWNER\";"

for TBL in $(pgExec "SELECT table_name FROM information_schema.tables WHERE table_schema = '$SCHEMA';") \
           $(pgExec "SELECT table_name FROM information_schema.views WHERE table_schema = '$SCHEMA';"); do
	pgExecEcho "ALTER TABLE \"$SCHEMA\".\"$TBL\" OWNER TO $OWNER;"
done

for SEQ in $(pgExec "SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = '$SCHEMA';"); do
	pgExecEcho "ALTER SEQUENCE \"$SCHEMA\".\"$SEQ\" OWNER TO $OWNER;"
done

# for FUNC in $(pgExec "SELECT quote_ident(p.proname) || '(' || pg_catalog.pg_get_function_identity_arguments(p.oid) || ')' \
#                       FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace \
#                       WHERE n.nspname = '$SCHEMA';"); do
# pgExecEcho "ALTER FUNCTION \"$SCHEMA\".$FUNC OWNER TO $OWNER;"
# done
