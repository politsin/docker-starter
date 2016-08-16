#!/bin/bash

set -e

MYSQL_DATA_DIR=/var/lib/mysql

docker_mysql_init(){

  rm -rf /var/lib/mysql/*
  
  set -- mysqld "$@"
  
  sed "s/password = .*/password = $MYSQL_ROOT_PASSWORD /g" -i /etc/mysql/debian.cnf
  sed "s/debian-sys-maint/root /g" -i /etc/mysql/debian.cnf
  
	if [ ! -d "$MYSQL_DATA_DIR/mysql" ]; then
		# If the password variable is a filename we use the contents of the file

		echo 'Initializing database'
		"$@" --initialize-insecure=on
		echo 'Database initialized'

		"$@" --skip-networking &
		pid="$!"

		mysql=( mysql --protocol=socket -uroot )

		for i in {30..0}; do
			if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
				break
			fi
			echo 'MySQL init process in progress...'
			sleep 1
		done
		if [ "$i" = 0 ]; then
			echo >&2 'MySQL init process failed.'
			exit 1
		fi

		mysql_tzinfo_to_sql /usr/share/zoneinfo | "${mysql[@]}" mysql
		
		"${mysql[@]}" <<-EOSQL
			-- What's done in this file shouldn't be replicated
			--  or products like mysql-fabric won't work
			SET @@SESSION.SQL_LOG_BIN=0;
			DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys');
			CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
			GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
			CREATE USER 'drupal'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}' ;
			CREATE DATABASE drupal DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
			GRANT ALL ON drupal.* TO 'drupal'@'localhost' ;
			DROP DATABASE IF EXISTS test ;
			FLUSH PRIVILEGES ;
			EOSQL
    
    echo
    echo
    echo
	echo 'Done!!!'
    echo
    echo
    echo

		if ! kill -s TERM "$pid" || ! wait "$pid"; then
			echo >&2 'MySQL init process failed.'
			exit 1
		fi

		echo
		echo 'MySQL init process done. Ready for start up.'
		echo
	fi
}

if [ ! "$(ls -A /var/lib/mysql)" ]; then 
  docker_mysql_init
fi


