#!/bin/sh

set -e

# create acme.json
if [ ! -f /data/acme.json ]
then
  touch /data/acme.json
fi

# user only read and write permission for acme.json
chmod 600 /data/acme.json


echo "$@"

# run cmd
(exec /entrypoint.sh "$@")
