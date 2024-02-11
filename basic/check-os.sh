#!/bin/bash

#Extracted from https://github.com/litespeedtech/ols1clk/blob/master/ols1clk.sh
#This function checks the OS version (CentOS 6/7/8, Ubuntu 14/16/18/20, and Debian 7/8/9/10).

function check_os
{
    OSNAMEVER=
    OSNAME=
    OSVER=

    if [ -f /etc/redhat-release ] ; then
        cat /etc/redhat-release | grep " 6." >/dev/null
        if [ $? = 0 ] ; then
            OSNAMEVER=CENTOS6
            OSNAME=centos
            OSVER=6
        else
            cat /etc/redhat-release | grep " 7." >/dev/null
            if [ $? = 0 ] ; then
                OSNAMEVER=CENTOS7
                OSNAME=centos
                OSVER=7

            else
                cat /etc/redhat-release | grep " 8." >/dev/null
                if [ $? = 0 ] ; then
                    OSNAMEVER=CENTOS8
                    OSNAME=centos
                    OSVER=8
                fi
            fi
        fi
    elif [ -f /etc/lsb-release ] ; then
        cat /etc/lsb-release | grep "DISTRIB_RELEASE=14." >/dev/null
        if [ $? = 0 ] ; then
            OSNAMEVER=UBUNTU14
            OSNAME=ubuntu
            OSVER=trusty
        else
            cat /etc/lsb-release | grep "DISTRIB_RELEASE=16." >/dev/null
            if [ $? = 0 ] ; then
                OSNAMEVER=UBUNTU16
                OSNAME=ubuntu
                OSVER=xenial

            else
                cat /etc/lsb-release | grep "DISTRIB_RELEASE=18." >/dev/null
                if [ $? = 0 ] ; then
                    OSNAMEVER=UBUNTU18
                    OSNAME=ubuntu
                    OSVER=bionic
                    
                else
                    cat /etc/lsb-release | grep "DISTRIB_RELEASE=20." >/dev/null
                    if [ $? = 0 ] ; then
                        OSNAMEVER=UBUNTU20
                        OSNAME=ubuntu
                        OSVER=focal
                    fi
                fi
            fi
        fi
    elif [ -f /etc/debian_version ] ; then
        cat /etc/debian_version | grep "^7." >/dev/null
        if [ $? = 0 ] ; then
            OSNAMEVER=DEBIAN7
            OSNAME=debian
            OSVER=wheezy
        else
            cat /etc/debian_version | grep "^8." >/dev/null
            if [ $? = 0 ] ; then
                OSNAMEVER=DEBIAN8
                OSNAME=debian
                OSVER=jessie
            else
                cat /etc/debian_version | grep "^9." >/dev/null
                if [ $? = 0 ] ; then
                    OSNAMEVER=DEBIAN9
                    OSNAME=debian
                    OSVER=stretch
                else
                    cat /etc/debian_version | grep "^10." >/dev/null
                    if [ $? = 0 ] ; then
                        OSNAMEVER=DEBIAN10
                        OSNAME=debian
                        OSVER=buster
                    fi
                fi
            fi
        fi
    fi
}
