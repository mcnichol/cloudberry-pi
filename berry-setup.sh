#!/usr/bin/env bash

function program_exists {
    local return_=0
    hash $1 2>/dev/null || { local return_=1;}  
    echo "$return_"
}

#$sudo apt-get -y update
#$sudo apt-get -y dist-upgrade

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
 
#ZSH Setup 
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
    git clone git://github.com/robbyrussell/oh-my-zsh.git $ZSH
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
    sed "/^export ZSH=/ c\ ZSH=$ZSH" ~/.zshrc > ~/.zshrc-temp && mv ~/.zshrc-temp ~/.zshrc
fi


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
