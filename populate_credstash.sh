#!/bin/bash

# exit if no env specified
: ${1?"Usage: $0 ENVIRONMENT"}

env_file="envs/${1}.env"

echo "Decrypting $env_file...
"
blackbox_edit_start $env_file

echo "
Making sure ${1}-credentials DDB table exists..."
credstash -t ${1}-credentials setup

sha=$(git rev-parse HEAD)

echo "
Updating all credentials to version ${sha}
"
# get current revision hash
cat $env_file | while read line; do
  IFS='=' read -r key value <<< "$line"
  credstash -t ${1}-credentials put -v $sha $key $value
done

blackbox_shred_all_files
