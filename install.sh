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

while getopts ":p:d:h:v" opt; do
  case ${opt} in

    h)  usage; exit 0   ;;

    v)  echo "$0 -- Version $ScriptVersion"; exit 0  ;;

    d) dotfiles=${OPTARG} && git ls-remote "$dotfiles" || exit 1 ;;

    p) prgrmsfile=${OPTARGS} ;;

    ?)  echo -e "\nOption does not exist : ($OPTARG)\n"; usage && exit 1 ;;

  esac
done

[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/vagos/.dotfiles.git"
[ -z "$prgrmsfile"   ] && prgrmsfile="https://raw.githubusercontent.com/Vagos/vars/main/programs.csv"
[ -z "$aurhelper"    ] && aurhelper="yay"


#-----------------------------------------------------------------------
#  Utility functions
#-----------------------------------------------------------------------


installpkg() { pacman --noconfirm -S "$1"  ; } # >/dev/null 2>&1; &>/dev/null}

error() { printf "%s\n" "$1" >&2; exit 1; }

welcome() 
{
#  dialog --title "Welcome!" --msgbox "This is the VARS installer script!\n\nRelax and enjoy the installation!\n\n.t-Vagos" 10 60

  printf "Welcome!\n"
  printf "This is the $ScriptName installer script!\nRelax and enjoy the installation!\n\n-Vagos\n\n\n"
}

basiscinstall()
{
  echo "Installing the bare basics first..."

  for pkg in curl base-devel git zsh ; do 
    echo "Installing $pkg"
    installpkg $pkg
  done
}

refreshkeyrings()
{
  # dialog --tile "Info" --infobox "Refreshing Arch Keyring..." 4 30

  echo "Refreshing Arch Keyring"
 
  installpkg archlinux-keyring
}

maininstall()
{
  # dialog --title "$ScriptName Installation" --infobox "Installing $1: $2" 4 70
  echo "Installing $1: $2"
  # installpkg "$1"
  sleep 0.5
}

gitinstall()
{
   # program_name="$basename"
   sleep 1
}

aurinstall()
{
  sudo -u "$name" $aurhelper -S --noconfirm "$1" 
  echo "$pacman -Qqm" | grep -q "^$1$" && error "Failed to intall AUR package: $1"
}

pipinstall()
{
  [-x "$(command -v "pip")"] || installpkg "python-pip" 
  yes | pip install "$1"
}

manualinstall()
{
  sudo -u "$name" mkdir -p "repodir"
  sudo -u "$name" git clone --depth 1 "https://aur.archlinux.org/$1.git" "$srcdir/$1"
  cd "$repodir/$1"

  sudo -u $name -D "$srcdir/$1" makepkg --noconfirm -si || return 1
}


installprograms() # Install all the programs located in the programs file
{
  ( [ -f "$prgrmsfile" ] && cat "$prgrmsfile" | sed "/^#/d" > /tmp/programs.csv ) || curl -sL $prgrmsfile | sed "/^#/d" > /tmp/programs.csv
  nprgrms=$(wc -l < /tmp/programs.csv) # number of programs to install

  while IFS=, read -r tag program comment; do
    n=$((n+1))

    case "$tag" in 
      
      "A") aurinstall "$program" "$comment" ;;

       * ) maininstall "$program" "$comment" ;;

    esac

  done < /tmp/programs.csv
}

installdotfiles() # Install dotfiles with stow
{
  echo "Installing dotfiles..."

  [ -z $3 ] && branch="master"

  dtdir="/home/$name/.dotfiles"

  sudo -u "$name" git clone -b "$branch" --recure-submodules "$1" "$dtdir" 

  for dir in $dtdir/*/; do
    
    printf "Installing dotfiles for %s" $dir
    # stow dir

  done
}

getuseranspass()
{
  read -p "Please enter a username: " name

  while ! echo "$name" | grep -q "^[a-z_][a-z0-9_-]*$"; do 
    read -p "Please enter a (valid) username: " name
  done

  read -sp "Please enter a password: " pass
  read -sp "Please repeat your password: " passcnfrm

  while ! [ "$pass" = "$passcnfrm" ]; do
    echo "Passwords didn't match!"
    read -sp "Please enter a password: " pass
    read -sp "Please repeat your password: " passcnfrm
  done
}

adduser()
{
  echo "Adding user $name"

  useradd -m -g wheel -s /bin/zsh $name 
  mkdir -p /home/$name

  chown "$name":wheel /home/$name
  echo "$name:$pass" | chpasswd

  unset pass passcnfrm;

  export srcdir="/home/$name/.local/src"; mkdir -p $srcdir; chown -R "$name":wheel "$(dirname $srcdir)"
}

finalize()
{
  echo "All done!"
}

#-----------------------------------------------------------------------
#  Main installation
#-----------------------------------------------------------------------

welcome 

getuseranspass || error "Installation cancelled."

refreshkeyrings

basiscinstall

adduser || error "Couldn't add username and/or password."

# Allow user to run sudo without password.
newperms "%wheel ALL=(ALL) NOPASSWD: ALL"

# Install the aur helper
echo "Installing the AUR helper..."
manualinstall yay-bin || "Failed to install AUR helper."

installprograms

installdotfiles

finalize
