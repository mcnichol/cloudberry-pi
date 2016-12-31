#!/usr/bin/env bash

ORIGIN_DIR=$(pwd)
TEMP_DIR=$ORIGIN_DIR/temp
CONFIG_DIR=$ORIGIN_DIR/config

function program_exists {
    local return_=0
    hash $1 2>/dev/null || { local return_=1;}  
    echo "$return_"
}

function script_setup {
    if [ -d "$TEMP_DIR" ]; then
        echo "Temp Directory Exists: $TEMP_DIR"
	echo "Emptying Temp Directory"
        rm -rf $TEMP_DIR/*
    else
	mkdir $TEMP_DIR
    fi
    
    echo "Setup Complete"
}

function script_cleanup {
    if [ -d "$TEMP_DIR" ]; then
        echo "Removing Temp Directory"
        rm -rf $TEMP_DIR
    fi
    
    echo "Cleanup Complete"
}

######################################
#           SCRIPT SETUP             #
# Setup Directories and Temp Folders #
######################################
script_setup


#$sudo apt-get -y update
#$sudo apt-get -y dist-upgrade

###############################################
# Setup Locales and make Default Locale EN_US #
###############################################
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

######################################
# Make Keyboard default to US layout #
######################################
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

#oh-my-zsh setup
#https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
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
