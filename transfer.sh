#!/bin/bash

# Patrick Conley <pconley@uvic.ca>
# Last modified: 2012 Nov 05
#
# Summary: Copy all relevant files (data synchronized by Unison, config files,
# network configuration, mail settings), all normally-installed programs to
# Titus

localhost=$( uname -n )
sourcename="Bellgrove"
hostname="Titus"
username="pconley"
ssh_dest="$username@$hostname.local"
scriptpath=$( readlink -f $0 )

##############################################################################

# Function  : push {{{1
# Purpose   : Copy this file and ssh keys to Titus, then run &
#           : fork this script in pull mode on Titus.
#           : Copy unison profiles and unsynchronized (eg, gconf settings (if
#           : possible), network config (if it doesn't require root),
#           : Terminator profile, mail settings, Quodlibet DB) files to Titus;
#           : copy music to Titus
# Arguments : N/A
# Validation: - Ensure this computer isn't Titus
#             - Ensure Titus is connected via ethernet (ask for Y/n with read)
# Assumption: - open-ssh is installed on Titus
function push
{
   echo "Copying files from $localhost to $hostname"

   declare -a dir_list
   dir_list=( .quodlibet .config/terminator Music .gconf .unison .config/dconf
   Pictures Schoolwork Documents )

   # Check this script isn't being run from Titus
   if [[ $localhost == "$hostname" ]]
   then
      echo "This script can't be run from $localhost. Aborting"
      exit 1
   fi

   # Copy all files
   scp -r files/ssh $ssh_dest:~/.ssh || 
      ( echo "Could not connect. Try\n sudo apt-get install ssh" && exit 1 ) # ssh keys
   scp $0 $ssh_dest:~/               # this file

   cd $HOME
   rsync -av --progress ${dir_list[@]} $ssh_dest:~/

   # Fix .unison
   ssh $ssh_dest "rm -f ~/.unison/ar* ~/.unison/fp* ~/.unison/lk* ~/backup"

   echo "Done pushing files to $hostname"
}

##############################################################################

# Function  : setup {{{1
# Purpose   : Do some setup from Titus' end
function setup
{
   echo "Downloading files from $sourcehost to $hostname"

   if [[ $localhost != "$hostname" ]]
   then
      echo "This script can't be run from $localhost. Aborting"
      exit 1
   fi

   # Get the certificate to UVic's WiFi network
   wget "http://www.uvic.ca/dl/public/fr.php?filename=thawte.cer" -O /etc/ssl/certs/UVic_thawte.cer

   $scriptpath/setup/setup.sh
}

##############################################################################

# Function  : install_base {{{1
# Purpose   : Install essential programs on Titus:
#             - quodlibet PPA
#             - DCSS PPA
#             - chrome
#             - synapse
#             - terminator
#             - vim
#             - pidgin
#             - pidgin-plugin-pack
#             - quodlibet
#             - gtk-redshift
#             - ubuntu-restricted-extras
#             - compizconfig-setting-manager
#             - unison
#             - subversion
#             - git
#             - mercurial
#             - zsh
#             - octave (full)
#             - perl-doc (full)
#             - mpg123
#             - ogg123
#             - texlive-full (full)
#             - crawl
#             - freeciv
#             
# Arguments : N/A
# Validation: - Ensure this computer is Titus
function install_base
{
   echo "Installing (smaller) software on $hostname"

   declare -a package_list
   package_list=( quodlibet crawl synapse vim pidgin pidgin-plugin-pack finch
   gtk-redshift ubuntu-restricted-extras compizconfig-settings-manager unison
   subversion git mercurial zsh mpg123 vorbis-tools freeciv-client-gtk tmux
   exuberant-ctags )

   if [[ $localhost != "$hostname" ]]
   then
      echo "This script must be run from $hostname. Aborting"
      exit 1
   fi

   sudo apt-get install -y ${package_list[@]}
}

##############################################################################

# Function  : install_full {{{1
# Purpose   : Install all remaining programs. Separate from pull-local as this
#           : is meant to be done when I have a fast connection and no
#           : bandwidth cap (ie., from school)
# Arguments : N/A
# Validation: - Ensure this computer is Titus
function install_full
{
   echo "Installing (larger) software on $hostname"

   declare -a package_list
   package_list=( octave perl-doc texlive-full )

   if [[ $localhost != "$hostname" ]]
   then
      echo "This script must be run from $hostname. Aborting"
      exit 1
   fi

   sudo apt-get install -y ${package_list[@]}
}

# }}}1

##############################################################################

#####
##### MAIN #####
#####

while getopts ":hsu" opt
do
	case $opt in

      h  ) hostname=$OPTARG ;;
      s  ) sourcename=$OPTARG ;;
      u  ) username=$OPTARG ;;
		\? ) echo 'usage: transfer.sh [ options ]'
 		     exit 1
	esac
done
shift $(($OPTIND-1))

if [[ $1 == "push" ]]
then
   push
elif [[ $1 == "setup" ]]
then
   setup
elif [[ $1 == "base" ]]
then
   install_base
elif [[ $1 == "full" ]]
then
   install_full
else
   if [[ $hostname == $localhost ]]
   then
      push
   else
      setup
      install_base
   fi
fi
