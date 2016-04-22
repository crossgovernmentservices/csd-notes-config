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

echo "
Updating credstash with config from terraform
"
cd ../csd-notes-infrastructure

# always delete local tfstate files before doing anything else, because
# terraform blindly pushes any local state to remote storage as a first step
rm ./*.tfstate*
rm ./.terraform/*.tfstate*

terraform remote config -backend=s3 -backend-config="bucket=csd-notes-terraform"\
  -backend-config="key=${ENV}.tfstate" -backend-config="region=eu-west-1"

terraform remote pull

echo "
Updating DB_HOST
"
credstash -t notes-${1}-credentials put \
    -v $sha DB_HOST $(terraform output rds_main_address)
