#!/bin/bash

# run migrate
cd app
python manage.py migrate

# back to root
cd ..

/usr/local/bin/uwsgi uwsgi.ini