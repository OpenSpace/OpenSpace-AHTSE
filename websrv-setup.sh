#!/bin/bash
# This script is used to setup the AHTSE server for OpenSpace.
# It is intended to be run on a fresh Ubuntu 22.04 LTS installation.
# It will install all required dependencies, build the AHTSE modules,
# and configure Apache to serve the OpenSpace web directory.

echo "AHTSE Server Setup"

echo "Installing dependencies..."
sudo apt install -y apache2 apache2-dev gdal-bin libgdal-dev build-essential gcc g++ git

echo "Creating directories..."
for dir in $HOME/wms_modules $HOME/modules $HOME/lib $HOME/include; do
    if [ -d $dir ]; then
        echo "Directory $dir already exists. Skipping..."
    else
        mkdir $dir
    fi
done

echo "Setting library configuration..."
sudo cp /etc/ld.so.conf.d/libc.conf /etc/ld.so.conf.d/libc.conf.backup
echo "$HOME/lib" | sudo tee -a /etc/ld.so.conf.d/libc.conf

echo "Cloning required dependencies..."
cd $HOME/wms_modules
for repo in libahtse AHTSE libicd mod_mrf mod_receive mod_sfim mod_reproject mod_convert; do
    if [ -d $repo ]; then
        echo "Repository $repo already exists. Skipping..."
    else
        git clone https://github.com/lucianpls/$repo.git
    fi
done

echo "Building mod_receive..."
cd $HOME/wms_modules/mod_receive/src
cp Makefile.lcl.example Makefile.lcl
make
make install

echo "Building libicd..."
cd $HOME/wms_modules/libicd/src
cp Makefile.lcl.example Makefile.lcl
make
make install

echo "Building libahtse..."
cd $HOME/wms_modules/libahtse/src
cp Makefile.lcl.example Makefile.lcl
make
make install

echo "Building mod_mrf..."
cd $HOME/wms_modules/mod_mrf/src
cat << 'MRF_MAKE' > Makefile.lcl
APXS = apxs
PREFIX ?= $(HOME)
includedir = $(shell $(APXS) -q includedir 2>/dev/null)
EXTRA_INCLUDES = $(shell $(APXS) -q EXTRA_INCLUDES 2>/dev/null)
EXTRA_INCLUDES += -I../../libahtse/src
EXTRA_INCLUDES += -I../../libicd/src
EXTRA_INCLUDES += -I../../mod_receive/src
LIBTOOL = $(shell $(APXS) -q LIBTOOL 2>/dev/null)
LIBEXECDIR = \$(shell \$(APXS) -q libexecdir 2>/dev/null)
EXP_INCLUDEDIR = $(PREFIX)/include

# SUDO = sudo
CP = cp
DEST = $(PREFIX)/modules
MRF_MAKE
make
make install

echo "Building mod_convert..."
cd $HOME/wms_modules/mod_convert/src
cp Makefile.lcl.example Makefile.lcl
make
make install

echo "Building mod_reproject/mod_retile..."
cd $HOME/wms_modules/mod_reproject/src
cp Makefile.lcl.example Makefile.lcl
make
make install

echo "Building mod_sfim..."
cd $HOME/wms_modules/mod_sfim/src
cp Makefile.lcl.example Makefile.lcl
make
make install

cd $HOME

echo "Installing Apache Modules..."
echo "Installing mod_mrf..."
cat << MRF_MOD | sudo tee /etc/apache2/mods-available/mrf.load
LoadFile $HOME/modules/libahtse.so
LoadModule mrf_module $HOME/modules/mod_mrf.so
MRF_MOD
sudo ln -s /etc/apache2/mods-available/mrf.load /etc/apache2/mods-enabled/mrf.load

echo "Installing mod_convert..."
cat << CONVERT_MOD | sudo tee /etc/apache2/mods-available/convert.load
LoadFile $HOME/modules/libahtse.so
LoadModule convert_module $HOME/modules/mod_convert.so
CONVERT_MOD
sudo ln -s /etc/apache2/mods-available/convert.load /etc/apache2/mods-enabled/convert.load

echo "Installing mod_receive..."
cat << RECEIVE_MOD | sudo tee /etc/apache2/mods-available/mrf.load
LoadModule receive_module $HOME/modules/mod_receive.so
RECEIVE_MOD
sudo ln -s /etc/apache2/mods-available/receive.load /etc/apache2/mods-enabled/receive.load

echo "Installing mod_retile..."
cat << RETILE_MOD | sudo tee /etc/apache2/mods-available/mrf.load
LoadModule retile_module $HOME/modules/mod_retile.so
RETILE_MOD
sudo ln -s /etc/apache2/mods-available/retile.load /etc/apache2/mods-enabled/retile.load

echo "Installing mod_sfim..."
cat << SFIM_MOD | sudo tee /etc/apache2/mods-available/mrf.load
LoadModule sfim_module $HOME/modules/mod_sfim.so
SFIM_MOD
sudo ln -s /etc/apache2/mods-available/sfim.load /etc/apache2/mods-enabled/sfim.load

echo "Restarting Apache and verifying modules are installed..."
sudo apachectl restart

echo "Creating OpenSpace web directory..."
sudo mkdir /var/www/openspace
sudo chown -R www-data:www-data /var/www/openspace/*

sudo cat << APACHE | sudo tee /etc/apache2/sites-available/001-openspace.conf
<VirtualHost *:80>
    ServerName openspace.maps
    DocumentRoot /var/www/openspace
    <Directory />
        Options +Indexes
        Require all granted
    </Directory>
</VirtualHost>
APACHE

sudo ln -s /etc/apache2/sites-available/001-openspace.conf /etc/apache2/sites-enabled/001-openspace.conf
sudo apachectl restart

echo "AHTSE server install complete!"