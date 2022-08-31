#!/bin/bash

set -euo pipefail

function warning() {
	echo $* 1>&2
}

scriptpath=$(realpath $0)

target_dir=${1:-}
source_dir=${2:-}
conf_dir=${3:-}

test -z "${target_dir}" && target_dir=/var/www/html
test -z "${source_dir}" && source_dir=$(dirname $scriptpath)/webconf
test -z "${conf_dir}" && conf_dir=/usr/lib64/httpd/webconf

warning "Searching in \"${source_dir}\""

# reset conf if exists
echo "# ahtse.conf" > ahtse.conf

for filepath in $(find $source_dir -type f -iname \*.webconf) ; do

	pathname=$(dirname  -- $filepath)
	filename=$(basename -- $filepath)
	filestub=${filename%.*}

	filename_dat=$(awk '/DataFile/  {gsub(".*/","");print}' $filepath)
	filename_idx=$(awk '/IndexFile/ {gsub(".*/","");print}' $filepath)

	pathname_new=${pathname/${source_dir}/${target_dir}}/${filestub}
	filepath_new=${pathname_new}/$filename
	filepath_dat=${pathname_new}/$filename_dat
	filepath_idx=${pathname_new}/$filename_idx
	filepath_conf=${conf_dir}/$filename

	if test -f $filepath_dat ; then
		warning "Data file found: ${filepath_dat}"
	else
		warning "No data file found for: ${filepath_dat} (skipping)"
 		continue
	fi

	if test -f $filepath_idx ; then
		warning "Index file found: ${filepath_idx}"
	else
		warning "No index file found for: ${filepath_idx} (skipping)"
 		continue
	fi

	# update webconf for local paths
	cp $filepath $filepath_conf
	sed -i "s,DataFile.*.,DataFile ${filepath_dat},g"   $filepath_conf
	sed -i "s,IndexFile.*.,IndexFile ${filepath_idx},g" $filepath_conf

	# create Apache httpd Directory stanza
	sed 's/^\t//' << EOF >> ahtse.conf

	<Directory ${pathname_new}>
	   Options -Indexes -FollowSymLinks -ExecCGI
	   MRF_RegExp */tile/.*
	   MRF_ConfigurationFile $filepath_conf
	</Directory>
EOF

done

# old defaults...
#target_dir=/mnt/e/os/mrf
#target_dir=/openspace_data
#target_dir=/var/www/html
