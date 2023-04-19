#!/usr/bin/env bash

. ./pg_envs.sh

getHelp () {
	cat <<- EOF

		Usage: $0 options

		This script create role with rights (Read-Only).

		Example: ./pg_rbac_create_role_ro.sh -d example_db -r example_db_admin -o example_db_ro -u example_db_username -s example_db_schema

		OPTIONS:

      -h   Show this message
      -d   Database
      -r   Role (ADMIN)
      -o   Role (RO)
      -u   Username
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

while getopts 'hd:r:o:u:s:' OPTION; do
	case $OPTION in
		h) getHelp; exit 1;;
		d) DB=$OPTARG;;
		r) ROLE_ADMIN=$OPTARG;;
		o) ROLE_RO=$OPTARG;;
		u) USER=$OPTARG;;
		s) SCHEMA=$OPTARG;;
	esac
done

if [ -z "$DB" ] || [ -z "$ROLE_ADMIN" ] || [ -z "$ROLE_RO" ]; then
	getHelp
	exit 1
fi

pgExec "CREATE ROLE $ROLE_ADMIN;
				CREATE ROLE $ROLE_RO;
				ALTER DEFAULT PRIVILEGES FOR ROLE $ROLE_ADMIN IN SCHEMA $SCHEMA GRANT SELECT ON TABLES TO $ROLE_RO;
				ALTER DEFAULT PRIVILEGES FOR ROLE $ROLE_ADMIN IN SCHEMA $SCHEMA GRANT USAGE, SELECT ON SEQUENCES TO $ROLE_RO;
				GRANT SELECT ON ALL TABLES IN SCHEMA $SCHEMA TO $ROLE_RO;
				GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA $SCHEMA TO $ROLE_RO;
				GRANT $ROLE_RO TO $USER;
				ALTER DATABASE $DB OWNER TO $ROLE_ADMIN;"
