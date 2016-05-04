#!/bin/bash

# exit if no env specified
: ${1?"Usage: $0 ENVIRONMENT"}

ENV=${1}

env_file="envs/${ENV}.env"

echo "Decrypting $env_file...
"
blackbox_edit_start $env_file

# get last-changed revision hash for this env file (not the repo)
sha=$(git --no-pager log --pretty=format:%H -n 1 -- ${env_file}.gpg)

echo "
Updating all credentials to version ${sha}
"
cat $env_file | while read line; do
  IFS='=' read -r key value <<< "$line"

  # check if value already exists for this key at this version, and only `put`
  # if it doesn't
  credstash -t notes-${ENV}-credentials \
    -r eu-west-1 get -v $sha $key >/dev/null 2>/dev/null

  if [ $? -eq 0 ]
  then
    echo "${key} at version ${sha} already exists."
  else
    credstash -t notes-${ENV}-credentials -r eu-west-1 \
      put -k alias/notes-${ENV}-credentials -v $sha $key $value
  fi
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


update_credstash_from_terraform () {
  echo "
  Updating ${1} to version ${sha}
  "

  credstash -t notes-${ENV}-credentials \
    -r eu-west-1 get -v $sha ${1} >/dev/null 2>/dev/null

  if [ $? -eq 0 ]
  then
    echo "${1} at version ${sha} already exists."
  else
    credstash -t notes-${ENV}-credentials -r eu-west-1 \
      put -k alias/notes-${ENV}-credentials -v $sha ${1} ${2}
  fi
}


update_credstash_from_terraform DB_HOST $(terraform output rds_main_address)
