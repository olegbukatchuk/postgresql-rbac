#!/usr/bin/env bash

. ./pg_envs.sh

getHelp () {
	cat <<- EOF

		Usage: $0 options

		This script create user.

		Example: ./pg_rbac_create_user.sh -u example_db_username -p example_db_password [-a]

		OPTIONS:

      -h   Show this message
      -u   Username
      -p   Password
      -a   Administrative user

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

INH=""

while getopts 'hu:p:a' OPTION; do
	case $OPTION in
		h) getHelp; exit 1;;
		u) USER=$OPTARG;;
		p) PASS=$OPTARG;;
                a) INH="NOINHERIT";;
	esac
done

if [ -z "$USER" ] || [ -z "$PASS" ]; then
	getHelp
	exit 1
fi

pgExec "CREATE USER $USER WITH $INH ENCRYPTED PASSWORD '$PASS';"
