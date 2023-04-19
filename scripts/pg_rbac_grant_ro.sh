#!/usr/bin/env bash

. ./pg_envs.sh

getHelp () {
	cat <<- EOF

		Usage: $0 options

		This script grants Read-Only privileges to a specified role on all tables, views
		and sequences in a database schema and sets them as default.

		Example: ./pg_rbac_grant_ro.sh -d example_db -r example_db_ro -s example_db_schema

		OPTIONS:

      -h   Show this message
      -d   Database
      -r   Role (RO)
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
		r) ROLE_RO=$OPTARG;;
		s) SCHEMA=$OPTARG;;
	esac
done

if [ -z "$DB" ] || [ -z "$ROLE_RO" ]; then
	getHelp
	exit 1
fi

pgExec "GRANT CONNECT ON DATABASE $DB TO $ROLE_RO;
				GRANT USAGE ON SCHEMA $SCHEMA TO $ROLE_RO;
				GRANT SELECT ON ALL TABLES IN SCHEMA $SCHEMA TO $ROLE_RO;
				GRANT SELECT ON ALL SEQUENCES IN SCHEMA $SCHEMA TO $ROLE_RO;"

# pgExec "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA $SCHEMA TO $ROLE_RO;
#	  			ALTER DEFAULT PRIVILEGES IN SCHEMA $SCHEMA GRANT EXECUTE ON FUNCTIONS TO $ROLE_RO;"
