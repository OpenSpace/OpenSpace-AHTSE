# OpenSpace-AHTSE
Setup scripts and configuration files for OpenSpace map servers.

Asumes successful setup of [Apache HTTPD Tile Server Ecosystem](https://github.com/lucianpls/AHTSE)

## Map config files
webconf/ contains configuration files for all the available maps.

## Apache Config generation
genconf.sh will create a configuration file for apache by looking in the DATA_FOLDER path for maps that match the available configuration files. For available maps, genconf will create an entry in AHTSE.conf with the correct paths, along with updating the paths in the .webconf files. 

## New maps
To add a new map, add it's .webconf file to the repository. 

## TODO
Script should offer to download maps that are not available on the local system from the Utah mirror. 

Script Should should generate index.html file for available maps.

Map preview links could be included or generated and linked in index.html. Such as [http://openspace.sci.utah.edu/Mars/CTX/](http://openspace.sci.utah.edu/Mars/CTX/])

Could include help for setup of AHTSE on common distros (CentOS and Ubuntu)

