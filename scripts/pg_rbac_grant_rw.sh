#!/usr/bin/env bash

. ./pg_envs.sh

getHelp () {
	cat <<- EOF

		Usage: $0 options

		This script grants Read-Write privileges to a specified role on all tables, views
		and sequences in a database schema and sets them as default.

		Example: ./pg_rbac_grant_rw.sh -d example_db -r example_db_rw -s example_db_schema

		OPTIONS:

      -h   Show this message
      -d   Database
      -r   Role (RW)
      -s   Schema (default: public)

EOF
}

pgExec() {
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

while getopts 'hd:r:s:' OPTION; do
	case $OPTION in
		h) getHelp; exit 1;;
		d) DB=$OPTARG;;
		r) ROLE_RW=$OPTARG;;
		s) SCHEMA=$OPTARG;;
	esac
done

if [ -z "$DB" ] || [ -z "$ROLE_RW" ]; then
	getHelp
	exit 1
fi

pgExec "GRANT CONNECT ON DATABASE $DB TO $ROLE_RW;
				GRANT USAGE ON SCHEMA $SCHEMA TO $ROLE_RW;
				GRANT SELECT ON ALL TABLES IN SCHEMA $SCHEMA TO $ROLE_RW;
				GRANT SELECT ON ALL SEQUENCES IN SCHEMA $SCHEMA TO $ROLE_RW;"

# pgExec "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA $SCHEMA TO $ROLE_RW;
#					ALTER DEFAULT PRIVILEGES IN SCHEMA $SCHEMA GRANT EXECUTE ON FUNCTIONS TO $ROLE_RW;"
