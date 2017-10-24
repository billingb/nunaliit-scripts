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

month_day=`date +"%d"`
week_day=`date +"%u"`

if [ "$month_day" -eq 1 ] ; then #first day of month create monthly
  backup_sub_dir=monthly
else
  if [ "$week_day" -eq 7 ] ; then #sunday create week
    backup_sub_dir=weekly
  else # On any regular day do
    backup_sub_dir=daily
  fi
fi

if [ ! -d "${backup_dir}" ]; then
  echo "Backup directory does not exist: ${backup_dir}"
  exit 1
fi

if [ ! -d "${backup_dir}/${backup_sub_dir}" ]; then
  mkdir ${backup_dir}/${backup_sub_dir}
fi

tar_cmd="tar -czf ${backup_dir}/${backup_sub_dir}/${atlas_name}_$(/bin/date +%Y%m%d_%H%M%S).tar.gz -C ${atlas_parent_dir} ${atlas_name}"
echo "Running tar command: ${tar_cmd}"
${tar_cmd}

#delete all daily files older then 2 weeks
find ${backup_dir}/daily/ -maxdepth 1 -mtime +14 -exec rm -rv {} \;

#delete all weekly files older then 12 weeks
find ${backup_dir}/weekly/ -maxdepth 1 -mtime +84 -exec rm -rv {} \;

#delete all monthly files older then 2 years
find ${backup_dir}/monthly/ -maxdepth 1 -mtime +730 -exec rm -rv {} \;

cd -