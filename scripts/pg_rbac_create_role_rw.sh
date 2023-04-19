#!/usr/bin/env bash

. ./pg_envs.sh

getHelp () {
	cat <<- EOF

		Usage: $0 options

		This script create role with rights (Read-Write).

		Example: ./pg_rbac_create_role_rw.sh -d example_db -r example_db_admin -w example_db_rw -u example_db_username -s example_db_schema

		OPTIONS:

      -h   Show this message
      -d   Database
      -r   Role (ADMIN)
      -w   Role (RW)
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

while getopts 'hd:r:w:u:s:' OPTION; do
	case $OPTION in
		h) getHelp; exit 1;;
		d) DB=$OPTARG;;
		r) ROLE_ADMIN=$OPTARG;;
		w) ROLE_RW=$OPTARG;;
		u) USER=$OPTARG;;
		s) SCHEMA=$OPTARG;;
	esac
done

if [ -z "$DB" ] || [ -z "$ROLE_ADMIN" ] || [ -z "$ROLE_RW" ]; then
	getHelp
	exit 1
fi

pgExec "CREATE ROLE $ROLE_ADMIN;
				CREATE ROLE $ROLE_RW;
				ALTER DEFAULT PRIVILEGES FOR ROLE $ROLE_ADMIN IN SCHEMA $SCHEMA GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO $ROLE_RW;
				ALTER DEFAULT PRIVILEGES FOR ROLE $ROLE_ADMIN IN SCHEMA $SCHEMA GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO $ROLE_RW;
				GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA $SCHEMA TO $ROLE_RW;
				GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA $SCHEMA TO $ROLE_RW;
				GRANT $ROLE_RW TO $USER;
				ALTER DATABASE $DB OWNER TO $ROLE_ADMIN;"
