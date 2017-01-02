#!/usr/bin/env bash

ORIGIN_DIR=$(pwd)
TEMP_DIR=$ORIGIN_DIR/temp
CONFIG_DIR=$ORIGIN_DIR/config

program_exists() {
    local return_=0
    hash $1 2>/dev/null || { local return_=1;}  
    echo "$return_"
}

script_setup(){
    if [ -d "$TEMP_DIR" ]; then
        echo "Temp Directory Exists: $TEMP_DIR"
	echo "Emptying Temp Directory"
        rm -rf $TEMP_DIR/*
    else
	mkdir $TEMP_DIR
    fi
    
    echo "Script Setup Complete"
}

script_cleanup(){
    if [ -d "$TEMP_DIR" ]; then
        echo "Removing Temp Directory"
        rm -rf $TEMP_DIR
    fi
    
    sudo apt-get -y autoremove
    sudo apt-get -y clean

    echo "Cleanup Complete"
}

get_init_sys(){
    if command -v systemctl > /dev/null && systemctl | grep -q '\-\.mount'; then
        SYSTEMD=1
    elif [ -f /etc/init.d/cron ] && [ ! -h /etc/init.d/cron ]; then
        SYSTEMD=0
    else
        echo "Unrecognised init system"
        return 1
    fi
}

######################################
#           SCRIPT SETUP             #
# Setup Directories and Temp Folders #
######################################
script_setup

########################################
# Update Raspberry Pi to latest Distro #
########################################
sudo apt-get -y update
sudo apt-get -y dist-upgrade

#####################################
# Default to Console Only Autologin #
#####################################
echo "Setting up Autologin to Console"
    sudo systemctl set-default multi-user.target
#    sudo sh -c 'ln -fs /etc/systemd/system/autologin@.service /etc/systemd/system/getty.target.wants/getty@tty1.service'
#    [ -e /etc/init.d/lightdm ] && sudo update-rc.d lightdm disable 2
#    sudo sed /etc/inittab -i -e "s/1:2345:respawn:\/sbin\/getty --noclear 38400 tty1/1:2345:respawn:\/bin\/login -f pi tty1 <\/dev\/tty1 >\/dev\/tty1 2>&1/"

#############
# SSH Setup #
#############
echo "Setting up SSH on Boot"
sudo sh -c 'update-rc.d ssh enable && invoke-rc.d ssh start'

#####################
# GIT Configuration #
#####################
git config --global push.default simple
git config --global user.email "mcnichol.m@gmail"
git config --global user.name "Merklet"

#####################################################
# Setup Locales and Default Keyboard Layout (EN_US) #
#####################################################
locale_pkg=$(dpkg -l locales | grep -i locales)
installed=$(echo $locale_pkg | awk '{print $1}')
package_name=$(echo $locale_pkg | awk '{print $2}')

if [ "$package_name" = "locales" ]; then
    echo "Locales Installed"
else
    echo "Locales Not Installed. Installing"
    aptitude install locales
fi

sed "/^XKBLAYOUT=/ c\XKBLAYOUT=\"us\"" /etc/default/keyboard > $TEMP_DIR/keyboard.tmp

IS_VALID_KEYBOARD_FILE=$(cat $TEMP_DIR/keyboard.tmp | grep 'XKBLAYOUT="us"' | wc -l)
if [ $IS_VALID_KEYBOARD_FILE -eq 1 ]; then
    sudo cp $TEMP_DIR/keyboard.tmp  /etc/default/keyboard
else
    echo "Error creating US Keyboard Layout"
    echo "Keyboard Temp File: "
    cat $TEMP_DIR/keyboard.tmp
fi

#############
# ZSH Setup #
#############
CHECK_ZSH_INSTALLED=$(grep /zsh$ /etc/shells | wc -l)
if [ ! $CHECK_ZSH_INSTALLED -ge 1 ]; then
    printf "Zsh is not installed"
    sudo apt-get -y install zsh
fi

sudo chsh -s $(which zsh)

###################
# oh-my-zsh setup #
###################
#Source: https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
if [ ! -n "$ZSH" ]; then
    ZSH=~/.oh-my-zsh
fi

if [ -d "$ZSH" ]; then
    printf "Oh My Zsh Already Installed\n"
    printf "Remove $ZSH if you want to re-install\n"
else
    git clone --depth=1 git://github.com/robbyrussell/oh-my-zsh.git $ZSH
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
    sed "/^export ZSH=/ c\ ZSH=$ZSH" ~/.zshrc > ~/.zshrc-temp && mv ~/.zshrc-temp ~/.zshrc
fi

cat $CONFIG_DIR/zshrc.config.sh >> ~/.zshrc

#VIM Setup
if [ $(program_exists vim) -eq 0 ]; then
    echo "VIM Already Installed"
else
    sudo apt-get -y install vim
fi

#TMUX Setup
if [ $(program_exists tmux) -eq 0 ]; then
    echo "TMUX Already Installed"
else
    sudo apt-get -y install tmux
fi

#Setup Bash Support (IDE Behavior)
if [ ! -d $TEMP_DIR ]; then
    mkdir $TEMP_DIR
fi

cd $TEMP_DIR

if [ ! -d ~/.vim ]; then
    mkdir ~/.vim
fi

if [ ! -d ~/.vim/bash-support ]; then
    curl -o bash-support.zip http://www.vim.org/scripts/download_script.php?src_id=9890
    cd ~/.vim
    unzip $TEMP_DIR/bash-support.zip

    echo "Generating Helptags for Bash Support"
    helpztags ~/.vim/doc
else
    echo "Bash Support Plugin is Already Installed"
fi

script_cleanup
