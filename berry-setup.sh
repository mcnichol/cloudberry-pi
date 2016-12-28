#!/usr/bin/env bash

#sudo apt-get update
#sudo apt-get -y dist-upgrade

locale_pkg=$(dpkg -l locales | grep -i locales)
installed=$(echo $locale_pkg | awk '{print $1}')
package_name=$(echo $locale_pkg | awk '{print $2}')

if [ "$package_name" = "locales" ]; then
    echo "Locales Installed"
else
    echo "Locales Not Installed. Installing"
    aptitude install locales
fi

sudo apt-get -y install vim
sudo apt-get -y install tmux


