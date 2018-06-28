#!/bin/bash
#
# Copyright (C) 2014 Wenva <lvyexuwenfa100@126.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

set -e

spushd() {
     pushd "$1" 2>&1> /dev/null
}

spopd() {
     popd 2>&1> /dev/null
}

info() {
     local green="\033[1;32m"
     local normal="\033[0m"
     echo -e "[${green}INFO${normal}] $1"
}

cmdcheck() {
    command -v $1>/dev/null 2>&1 || { error >&2 "Please install command $1 first."; exit 1; }   
}

error() {
     local red="\033[1;31m"
     local normal="\033[0m"
     echo -e "[${red}ERROR${normal}] $1"
}

curdir() {
    if [ ${0:0:1} = '/' ] || [ ${0:0:1} = '~' ]; then
        echo "$(dirname $0)"
    elif [ -L $0 ];then
        name=`readlink $0`
        echo $(dirname $name)
    else
        echo "`pwd`/$(dirname $0)"
    fi
}

myos() {
    echo `uname|tr "[:upper:]" "[:lower:]"`
}

#########################################
###           GROBLE DEFINE           ###
#########################################

VERSION=1.0.0
AUTHOR=smallmuou

#########################################
###             ARG PARSER            ###
#########################################

usage() {
cat << EOF
`basename $0` version $VERSION by $AUTHOR

USAGE: `basename $0` [OPTIONS]

DESCRIPTION:
    The script uses to enable eth name under centos7.

OPTIONS:
    -h                Show this help message and exit

EOF
exit 1
}

while getopts 'h' arg; do
    case $arg in
        h)
            usage
            ;;
        ?)
            usage
            ;;
    esac
done

shift $(($OPTIND - 1))


#########################################
###            MAIN ENTRY             ###
#########################################

# ifname number
change_ifcfg() {
    local base="/etc/sysconfig/network-scripts/ifcfg-"
    local srcfile=$base"$1"
    local dstfile=$base"eth"$2
    if [ -f $dstfile ];then
        info "already exist $dstfile"
    elif [ -f $srcfile ];then
        info "rename $srcfile to $dstfile ..."
        sed -i "s/^NAME=.*/NAME=eth$2/" $srcfile
        sed -i "s/^DEVICE=.*/DEVICE=eth$2/" $srcfile
        mv $srcfile $dstfile
    else
        info "not found $srcfile, generate $dstfile ..."
cat << EOF > $dstfile
TYPE=Ethernet
DEVICE=eth$2
ONBOOT=yes
BOOTPROTO=dhcp
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
NAME=eth$2
EOF
    fi
}

enable_eth() {
    local file='/etc/default/grub'
    if [ -f $file ];then
        if [ -z "`cat $file|sed -n '/GRUB_CMDLINE_LINUX/p'|sed -n '/net.ifnames=0 biosdevname=0/p'`" ];then
            sed -i '/GRUB_CMDLINE_LINUX/s/="/="net.ifnames=0 biosdevname=0 /' $file
        fi
        grub2-mkconfig -o /boot/grub2/grub.cfg
    else
        error "$file does not exit. can not enable eth name"
        exit 
    fi
}

interface_list_without_lo() {
    echo `ip address|awk '/mtu/{print $2}'|sed -n 's/://p'|sed -n '/lo/!p'`
}

enable_eth

num=0
for name in `interface_list_without_lo`;
do
    change_ifcfg $name $num
    num=`expr $num + 1`

done

info 'Enable eth successfully. please reboot to effect.'
