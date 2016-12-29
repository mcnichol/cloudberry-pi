#!/usr/bin/env bash


#Ask user for SUDO Pass
read -p "Enter SUDO Password: " -s pass

echo $pass

sudo apt-get -y update
sudo apt-get -y dist-upgrade

#Setup Locales and make Default Locale EN_US
locale_pkg=$(dpkg -l locales | grep -i locales)
installed=$(echo $locale_pkg | awk '{print $1}')
package_name=$(echo $locale_pkg | awk '{print $2}')

if [ "$package_name" = "locales" ]; then
    echo "Locales Installed"
else
    echo "Locales Not Installed. Installing"
    aptitude install locales
fi

#ZSH Setup and oh-my-zsh
echo $pass | sudo -S apt-get -y install zsh
echo $pass | sudo -S chsh -s $(which zsh)
touch ~/.zshrc

sudo apt-get -y install vim
sudo apt-get -y install tmux


