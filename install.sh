#!/bin/bash

ScriptVersion="0.0.1"
ScriptName="VARS"

function usage ()
{
    echo "Usage :  $0 [options]

    Options:
    -h|help       Display this message
    -v|version    Display script version"

}

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

while getopts ":d:h:v" opt; do
  case ${opt} in

    h)  usage; exit 0   ;;

    v)  echo "$0 -- Version $ScriptVersion"; exit 0  ;;

    d) dotfiles=${OPTARG} && git ls-remote "$dotfiles" || exit 1 ;;

    ?)  echo -e "\nOption does not exist : ($OPTARG)\n"; usage && exit 1 ;;

  esac
done

[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/vagos/.dotfiles.git"
[ -z "$programsfile" ] && programsfile="" 
[ -z "$aurhelper"    ] && aurhelper="yay"


installpkg() { pacman --noconfirm -S "$1" &>/dev/null ; } # >/dev/null 2>&1; }

error() { printf "%s\n" "$1" >&2; exit 1; }

welcome() 
{
  dialog --title "Welcome!" --msgbox "This is the VARS installer script!\n\nRelax and enjoy the installation!\n\n-Vagos" 10 60
}

refreshkeyrings()
{
  dialog --tile "Info" --infobox "Refreshing Arch Keyring..." 4 30
 
  installpkg archlinux-keyring
}

maininstall()
{
  dialog --title "$ScriptName Installation" --infobox "Installing $1.";
  installpkg "$1"
}

gitinstall()
{
  sleep 1
}

aurinstall()
{
  sleep 1
}

pipinstall()
{
 sleep 1
}



welcome 

# for i in $(seq 0 10 100) ; do sleep 1; echo 99 | dialog --gauge "Please wait" 10 70 0; done
# refreshkeyrings

installprograms()
{
  ( [ -f "$progsfile" ] && cp "$progsfile" /tmp/programs.csv ) || curl 
}
