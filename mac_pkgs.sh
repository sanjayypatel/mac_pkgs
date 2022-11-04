#!/bin/zsh
# Script: mac_pkgs.sh
# Main script that will loop through scripts/ on schedule

# mac_pkgs Main Script

# Reading config file
config_file="./mac_pkgs.cfg"

# Log configuration
log_file=$( cat $config_file | grep log_file | awk -F= '{print $2}' | tr -d ' ' )
export MAC_PKGS_LOG=$log_file
touch $log_file

# Logging function
log_data() {
	echo `date "+%a %b %d %T"` "${1}" | tee -a $log_file
}

# Log initial setup
log_data "===== ===== ===== ====="
log_data "mac_pkgs Main Script Start"
log_data "Config File: $config_file"
log_data "Log File: $log_file"

log_data "===== ===== ===== ====="

repo_path=$( cat $config_file | grep repo_path | awk -F= '{print $2}' | tr -d ' ' )
export MAC_PKGS_REPO=$repo_path
log_data "Repo Path: $repo_path"
if [ ! -d $repo_path ]
then
	log_data "ERROR: Repo Path $repo_path not found!"
	exit 1
fi

apps_path=$( cat $config_file | grep apps_path | awk -F= '{print $2}' | tr -d ' ' )
export MAC_PKGS_APPS=$apps_path
log_data "Apps Path: $apps_path"
if [ ! -d $apps_path ]
then
	log_data "ERROR: Apps Path $apps_path not found!"
	exit 1
fi

scripts_dir="$repo_path/scripts"
log_data "Scripts Directory: $scripts_dir"
if [ ! -d $scripts_dir ]
then
	log_data "ERROR: Scripts Directory $scripts_dir not found!"
	exit 1
fi

log_data "===== ===== ===== ====="

log_data "Looping through scripts directory."
for script  in $scripts_dir/*(.)
do
    log_data "Running $script"
    $script
done

log_data "mac_pkgs Main Script End"
log_data "===== ===== ===== ====="