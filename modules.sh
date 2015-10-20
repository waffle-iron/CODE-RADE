#!/bin/bash


# Script to set a few variables on the deploy side.
# this needs to find out what kind of machine it's been executed on and set the path to the
# CODE-RADE modules.

# Test with : docker run -t -v $PWD:$PWD -w $PWD <os> modules.sh
# e.g. docker run -t -v $PWD:$PWD -w $PWD centos:6 modules.sh
# e.g. docker run -t -v $PWD:$PWD -w $PWD ubuntu:14.04 modules.sh


# If CVMFS is mounted at $CVMFS_MOUNT - usually /cvmfs then the modules are at
# /cvmfs/<repo name>/modules

# We need to set the following variables :

# SITE - default = generic
# OS - no default.
# ARCH - default = x86_64

SITE="generic"
OS="undefined"
ARCH="undefined"
CVMFS_MOUNT="undefined"

# What architecture are we ?
ARCH=`uname -m`
# It's possible, but very unlikely that some wierdo wants to do this on a machine that's not
# Linux - let's provide for this instance
if [ $? != 0 ] ; then
  echo "My my, uname exited with a nonzero code. \n
  Are you trying to run this from a non-Linux machine ? \n
  Dude ! What's WRONG with you !?   \n\n
  Bailing out... aaaaahhhhhrrrggg...."

  exit 127
fi

# What OS are we on ?
# Strategy -
# 1. If LSB is present, use that - probably only the case for ubuntu machines
# 2. if not check /etc/debian_version
# 3. If not, check /etc/redhat_release - if there, check the version

# we go in order of likelihood... probably going to be CentOS machines before they're actually
# RH machines.
# TODO : condition for SuSE or Fedora machines. (ok, we don't compile against those yet)

# can haz LSB ?
LSB_PRESENT=`which lsb_release`
if [ $? != 0 ] ; then
  echo "No LSB found, checking files in /etc/"
  LSB_PRESENT=false
  # probably CEntOS /etc/redhat_release ?
  if [[ -h /etc/redhat-release  &&  -s /etc/centos-release ]] ; then
    echo "We're on a CEntOS machine"
    CENTOS_VERSION=`rpm -q --queryformat '%{VERSION}' centos-release`
    echo $CENTOS_VERSION
    # ok, close enough, we're on sl6
    OS="sl6"
    #  Time to suggest a compiler. Use /proc/version
  fi # We've set OS=sl6 and it's probably a CentOS machine. TODO : test on different machines for false positives.
  # We're probably a debian machine at this point
  if [ -s /etc/debian_release ] ; then
    echo "/etc/debian_release is present - seems to be a debian machine"
    IS_DEBIAN=true
    DEBIAN_VERSION=`cat /etc/debian_version | awk -F . '{print $1}'`
    if [ ${DEBIAN_VERSION} == 6 ] ; then
      echo "This seems to be Debian 6"
      echo "Setting your OS to u1404 - close enough"
    else
      echo "Debian version ${DEBIAN_VERSION} is not supported"
      exit 127
    fi
  fi

  else # lsb is present
    LSB_ID=`lsb_release -is`
    LSB_RELEASE=`lsb_release -rs`
    echo "You seem to be on LSB Release ${LSB_ID}, version ${LSB_RELEASE}..."
    if [[ ${LSB_ID} == 'Ubuntu' && ${LSB_RELEASE} == '14.04' ]] ; then
      echo "Cool, we test this, welcome :) ; Setting OS=u1404"
      OS="u1404"
    else if [[ ${LSB_ID} == 'Ubuntu' ]] ; then
      echo "Dude, you seem to be using an Ubuntu machine, but not the one we test for."
      echo "Setting OS to u1404... YMMV"
      echo "If you want to have this target certified, please request it of the devs "
      echo "by opening a ticket at https://github.com/AAROC/CODE-RADE/issues/new"
    OS="u1404"
  else
    echo "ahem..."
  fi
  fi
fi

if [ ${OS} == 'undefined' ] ; then
  echo "damn, OS is still undefined"
  echo "look dude, You're not CentOS , you're not Debian and you don't have LSB... CVMFS is not your problem right now."
  exit 127
fi

# Is CVMFS even available ?
#CVMFS_MOUNT=`cvmfs_config showconfig devrepo.sagrid.ac.za | grep CVMFS_MOUNT_DIR | awk

# we should check this in a more rigourous way, but we don't have time right now
echo "Setting CVMFS_MOUNT to /cvmfs/ for now. We will be awesomer later."


echo "**********************"
echo "Setting SITE=$SITE"
echo "Setting OS=$OS"
echo "Setting ARCH to $ARCH"

echo "Checking whether you have modules installed"

# Is "modules even available? "
if [ ! -n ${MODULESHOME} ] ; then
  echo "MODULESHOME is not set. Are you sure you have modules installed ? you're going to need it."
  echo "Exiting. We will have modules in CVMFS soon..."
  exit 1;
else
  echo "ok, you have modules at ${MODULESHOME}"
fi

# Update MODULEPATH

export MODULEPATH=${MODULEPATH}:${CVMFS_MOUNT_DIR}/devrepo.sagrid.ac.za
module avail
