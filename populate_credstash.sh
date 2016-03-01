#!/bin/bash
set -e

# exit if no env specified
: ${1?"Usage: $0 ENVIRONMENT"}

# make sure credstash table is present
credstash -t ${1}-credentials setup

# get current revision hash
sha=$(git rev-parse HEAD)

# store each key/value pair
cat ./${1}-creds.env | while read line; do
  IFS='=' read -r key value <<< "$line"
  credstash -t ${1}-credentials put $key -v $sha $value
  credstash -t ${1}-credentials put -v $sha $key $value
done
