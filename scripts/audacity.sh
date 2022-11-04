#!/bin/zsh
# Application Info
name="audacity"
expected_team_id="AWEYX923UX"

# Reading config file
#config_file="./mac_pkgs.cfg"
config_file=$MAC_PKGS_CONFIG
# Set disabled to 1 to prevent the packaging from proceeding.
disabled=0

# Log configuration
log_file=$MAC_PKGS_LOG
if [ -z $log_file ]
then
	echo "MAC_PKGS_LOG not set in env."
	exit 0
fi
touch $log_file

# Logging function
log_data() {
	echo `date "+%a %b %d %T"` "${1}" | tee -a $log_file
}

# Log initial setup
log_data "===== ===== ===== ====="
log_data "mac_pkgs $name Script Start"
log_data "Config File: $config_file"
log_data "Log File: $log_file"
log_data "===== ===== ===== ====="

repo_path=$MAC_PKGS_REPO
log_data "Repo Path: $repo_path"
if [ ! -d $repo_path ]
then
	log_data "ERROR: Repo Path $repo_path not found!"
	exit 1
fi

apps_path=$MAC_PKGS_APPS
log_data "Apps Path: $apps_path"
if [ ! -d $apps_path ]
then
	log_data "ERROR: Apps Path $apps_path not found!"
	exit 1
fi

# Log Application Info
log_data "Application name: $name"
log_data "Expected Team ID: $expected_team_id"

# Scrape for latest download info
download_url=$(curl -L --silent --fail "https://api.github.com/repos/audacity/audacity/releases/latest" | awk -F '"' "/browser_download_url/ && /dmg\"/ { print \$4; exit }")
app_new_version=$(curl -L --silent --fail "https://api.github.com/repos/audacity/audacity/releases/latest" | grep tag_name | cut -d '"' -f 4 | sed 's/[^0-9\.]//g')
log_data "Download URL: $download_url"

# Packaging information
required_pkg_name="audacity-macOS-$app_new_version-Intel.dmg"
app_dir="$apps_path/$name"
location="$app_dir/$required_pkg_name"
mount_path="$repo_path/mount"
app_name="Audacity.app"
log_data "App New Version: $app_new_version"
log_data "Required PKG Name: $required_pkg_name"

# Check for script disabled
if [[ $disabled == 1 ]]
then
    log_data "Latest $name is disabled. Exiting."
    exit 0
fi

# Check for latest pkg already existing.
log_data "Checking if latest is already cached."
if [ -f "$app_dir/$name-$app_new_version.pkg" ]
then
    log_data "$name-$app_new_version.pkg already cached. Exiting."
    exit 0
fi

# Verify app directory and download
log_data "Verifying app directory: $app_dir"
mkdir -p $app_dir
log_data "Downloading $name $app_new_version"
curl -L -o $location $download_url
download_check=$( ls -l $location )
if [ -z $download_check ]
then
	log_data "Error! $location not found!"
	exit 1
fi

# Mount dmg
log_data "Mounting $location"
hdiutil attach $location -mountpoint $mount_path | tee -a $log_file

log_data "Verifing Team ID matches $expected_team_id"
actual_team_id=$(spctl -a -vv $mount_path/$app_name 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
log_data "Downloaded Team ID: $actual_team_id"
if [[ $actual_team_id = $expected_team_id ]] ; then
	# Create package if downloaded Team ID and Expected Team ID match
    log_data "TeamID matches $expected_team_id"
    log_data "Creating pkg. Setting up pkg root in $app_dir/root"
    mkdir -p $app_dir/root/Applications
    cp -R $mount_path/$app_name $app_dir/root/Applications
    pkgbuild --root $app_dir/root $app_dir/$name-$app_new_version.pkg | tee -a $log_file
	log_data "Unmounting $location from $mount_path"
	hdiutil detach $mount_path | tee -a $log_file
    log_data "Cleaning up the download and pkg root."
	rm -rf $location
    rm -rf $app_dir/root
else
	# If Team IDs do not match, clean up and exit with error
    log_data "Error! Team ID does not match $expected_team_id! Verify download url!"
    log_data "Unmounting $$location from $mount_path"
    hdiutil detach $mount_parth | tee -a $log_file
    log_data "Deleting $location"
    rm -rf $location
    exit 1
fi

log_data "Cached app versions for $name:"
ls -la $app_dir | grep $name | tee -a $log_file