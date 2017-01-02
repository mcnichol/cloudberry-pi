#!/usr/bin/env bash

ORIGIN_DIR=$(pwd)
TEMP_DIR=$ORIGIN_DIR/temp
CONFIG_DIR=$ORIGIN_DIR/config
DEFAULT_PASSWORD="raspberry"

program_exists() {
    local return_=0
    hash > /dev/null 2>&1 || { local return_=1;}  
    echo "$return_"
}

script_setup(){
    printf "Running Setup Script\n"

    if [ -d "$TEMP_DIR" ]; then
        printf "Temp Directory Exists: $TEMP_DIR\n"
        printf "Emptying Temp Directory\n"
        rm -rf $TEMP_DIR/*
    else
        mkdir $TEMP_DIR
    fi
    
    printf "Script Setup Complete\n\n"
}

script_cleanup(){
    printf "\nRunning Cleanup Script\n"

    if [ -d "$TEMP_DIR" ]; then
        printf "Removing Temp Directory\n"
        rm -rf $TEMP_DIR
    fi
    
    sudo apt-get -yqq autoremove
    sudo apt-get -yqq clean

    printf "Cleanup Complete\n\n"
}

######################################
#           SCRIPT SETUP             #
# Setup Directories and Temp Folders #
######################################
script_setup

########################################
# Update Raspberry Pi to latest Distro #
########################################
printf "Updating Package Lists for the Pi\n"
sudo apt-get -yqq update
printf "Upgrading Distribution\n"
sudo apt-get -yqq dist-upgrade

#####################################
# Default to Console Only Autologin #
#####################################
printf "Setting up Autologin to Console\n"
sudo systemctl set-default multi-user.target
sudo sh -c 'ln -fs /etc/systemd/system/autologin@.service /etc/systemd/system/getty.target.wants/getty@tty1.service'

#############
# SSH Setup #
#############
printf "Setting up SSH on Boot\n"
    sudo sh -c 'update-rc.d ssh enable && invoke-rc.d ssh start'

#####################
# GIT Configuration #
#####################
printf "Exportin GIT Global Configurations\n"
git config --global push.default simple
git config --global user.email "mcnichol.m@gmail"
git config --global user.name "Merkle"

#####################################################
# Setup Locales and Default Keyboard Layout (EN_US) #
#####################################################
locale_pkg=$(dpkg -l locales | grep -i locales)
installed=$(echo $locale_pkg | awk '{print $1}')
package_name=$(echo $locale_pkg | awk '{print $2}')

if [ "$package_name" = "locales" ]; then
    printf "Locales Installed\n"
else
    printf "Locales Not Installed. Installing\n"
    aptitude install locales
fi

sed "/^XKBLAYOUT=/ c\XKBLAYOUT=\"us\"" /etc/default/keyboard > $TEMP_DIR/keyboard.tmp

IS_VALID_KEYBOARD_FILE=$(cat $TEMP_DIR/keyboard.tmp | grep 'XKBLAYOUT="us"' | wc -l)
if [ $IS_VALID_KEYBOARD_FILE -eq 1 ]; then
    sudo cp $TEMP_DIR/keyboard.tmp  /etc/default/keyboard
else
    printf "Error creating US Keyboard Layout\n"
    printf "Keyboard Temp File: \n"
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

printf "Changing Default Shell to ZSH\n"
echo $DEFAULT_PASSWORD | chsh -s $(which zsh) > /dev/null 2>&1

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

EXISTS_CUSTOM_CLOUDBERRY_ZSHRC=$(grep "cloudberry_script:START:CONFIG_MAIN" ~/.zshrc | wc -l )
if [ ! $EXISTS_CUSTOM_CLOUDBERRY_ZSHRC -ge 1 ]; then
    printf "Appending Custom zshrc Configuration\n"
    cat $CONFIG_DIR/zsh/zshrc.config.sh >> ~/.zshrc
else
    printf "~/.zshrc already written to.\nRemove custom configurations to re-write\n"
fi
#VIM Setup
if [ $(program_exists vim) -eq 0 ]; then
    printf "VIM Already Installed\n"
else
    sudo apt-get -y install vim
fi

#TMUX Setup
if [ $(program_exists tmux) -eq 0 ]; then
    printf "TMUX Already Installed\n"
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

    printf "Generating Helptags for Bash Support\n"
    helpztags ~/.vim/doc
else
    printf "Bash Support Plugin is Already Installed\n"
fi

script_cleanup
