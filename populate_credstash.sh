#!/bin/bash

# exit if no env specified
: ${1?"Usage: $0 ENVIRONMENT"}

env_file="envs/${1}.env"

echo "Decrypting $env_file...
"
blackbox_edit_start $env_file

echo "
Making sure ${1}-credentials DDB table exists..."
credstash -t notes-${1}-credentials setup

# get last-changed revision hash for this env file (not the repo)
sha=$(git --no-pager log --pretty=format:%H -n 1 -- ${env_file}.gpg)

echo "
Updating all credentials to version ${sha}
"
cat $env_file | while read line; do
  IFS='=' read -r key value <<< "$line"
  credstash -t notes-${1}-credentials put -v $sha $key $value
done

blackbox_shred_all_files
