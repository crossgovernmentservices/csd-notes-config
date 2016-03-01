#!/bin/bash
set -e

# exit if no env specified
: ${1?"Usage: $0 ENVIRONMENT"}

# make sure credstash table is present
credstash -t ${1}-credentials setup

# store each key/value pair
cat ./${1}-creds.env | while read line; do
  IFS='=' read -r key value <<< "$line"
  credstash -t ${1}-credentials put $key -a $value
done
