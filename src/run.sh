#!/bin/bash
until nc -z $MYSQL_HOSTNAME $MYSQL_PORT
do
  echo "Waiting for database connection..."
  # wait for 5 seconds before check again
  sleep 5
done

# run migrate
cd app
python manage.py migrate



# back to root
cd ..

/usr/local/bin/uwsgi uwsgi.ini