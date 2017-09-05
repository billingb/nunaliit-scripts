#!/bin/bash

usage="$(basename "$0") <backup directory> <atlas directory> -- Script to create a backup of the passed atlas"

if [[ $# -ne 2 ]]; then
  echo "Illegal number of argument. Usage:"
  echo $usage
  exit
fi

backup_dir=$1
atlas_dir=$2

KEEP_DUMP=1

cd $atlas_dir
#Find the nunaliit command to run
nunaliit_cmd=$(${atlas_dir}/extra/nunaliit.sh check | grep NUNALIIT_CMD | cut -d '=' -f 2 | sed 's/[[:space:]]//g')
dump_cmd="${nunaliit_cmd} dump --atlas-dir ${atlas_dir}"
echo "Running dump command: ${dump_cmd}"
${dump_cmd} > /dev/null

#Delete all but newest dump
old_dumps=$(ls -t ${atlas_dir}/dump | grep -v '/$' | tail -n +2)
for old_dump in ${old_dumps}
do
  del_cmd="rm -r ${atlas_dir}/dump/${old_dump}"
  echo "Deleting old dump dir: ${del_cmd}"
  ${del_cmd}
done

echo "Creating tarball"
atlas_parent_dir=$(dirname ${atlas_dir})
atlas_name=$(basename ${atlas_dir})

tar_cmd="tar -czf ${backup_dir}/${atlas_name}_$(/bin/date +%Y%m%d_%H%M%S).tar.gz -C ${atlas_parent_dir} ${atlas_name}"
echo "Running tar command: ${tar_cmd}"
${tar_cmd}

#delete all but newest 2 tar files
#old_backups=$(ls -t ${backup_dir} | grep -v '/$' | tail -n +3)
#for old_backup in ${old_backups}
#do
#  del_cmd="rm -r ${backup_dir}/${old_backup}"
#  echo "Deleting old backup: ${del_cmd}"
#  ${del_cmd}
#done
cd -