#!/bin/bash

# exit the script if any statement returns a non-true return value
set -e
# exit the script if any uninitialised variable
set -u
#  prevents errors in a pipeline from being masked
set -o pipefail
# Internal Field Separator splitting only on newlines and tab characters.
IFS=$'\n\t'
# check for root
#[ $EUID -ne 0 ] && { echo "You must be a root user"; exit 1; }

# Immutable global variables
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

# Set Colors
bold=$(tput bold)
reset=$(tput sgr0)
purple=$(tput setaf 171)
red=$(tput setaf 1)
green=$(tput setaf 76)
tan=$(tput setaf 3)
blue=$(tput setaf 38)
underline=$(tput sgr 0 1)

# Options and Usage
# -----------------------------------
usage() {
    cat << EOF
    usage: $PROGNAME options

    Program deletes files from filesystems to release space.
    It gets config file that define fileystem paths to work on, and whitelist rules to
    keep certain files.

     ${bold}OPTIONS:${reset}
       -c --config              configuration file containing the rules. use --help-config to see the syntax.
       -n --pretend             do not really delete, just how what you are going to do.
       -t --test                run unit test to check the program
       -v --verbose             Verbose. You can specify more then one -v to have more verbose
       -x --debug               debug
       -h --help                show this help
          --help-config         configuration help


    Examples:
       Run all tests:
       $PROGNAME --test all

       Run specific test:
       $PROGNAME --test test_string.sh

       Run:
       $PROGNAME --config /path/to/config/$PROGNAME.conf

       Just show what you are going to do:
       $PROGNAME -vn -c /path/to/config/$PROGNAME.conf
EOF
}

cmdline() {
    while getopts "nvhxt:c:" OPTION
    do
         case $OPTION in
         v)
             readonly VERBOSE=1
             ;;
         h)
             usage
             exit 0
             ;;
         x)
             readonly DEBUG='-x'
             set -x
             ;;
         t)
             RUN_TESTS=$OPTARG
             verbose VINFO "Running tests"
             ;;
         c)
             readonly CONFIG_FILE=$OPTARG
             ;;
         n)
             readonly PRETEND=1
             ;;
        esac
    done

    return 0
}

cmdline $ARGS
