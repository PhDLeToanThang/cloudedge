#!/bin/bash

#Created by https://thangletoan.wordpress.com
#This function behaves like a colored "echo."
#Usage: 
#say hello yellow blue ##hello in yellow color with blue background
#say hello cyan magenta ##hello in cyan color with magenta background
#say hello red ##hello in red color
#say hello ##= echo hello
#say hello w y ##hello in white color with yellow background
#say @Bhello g k ##bolded hello in green color with black background

function say
{
	echo_content=$1
	case $2 in
		black | k ) colorf=0 ;;
		red | r ) colorf=1 ;;
		green | g ) colorf=2 ;;
		yellow | y ) colorf=3 ;;
		blue | b ) colorf=4 ;;
		magenta | m ) colorf=5 ;;
		cyan | c ) colorf=6 ;;
		white | w ) colorf=7 ;;
		* ) colorf=N ;;
	esac
	case $3 in
		black | k ) colorb=0 ;;
		red | r ) colorb=1 ;;
		green | g ) colorb=2 ;;
		yellow | y ) colorb=3 ;;
		blue | b ) colorb=4 ;;
		magenta | m ) colorb=5 ;;
		cyan | c ) colorb=6 ;;
		white | w ) colorb=7 ;;
		* ) colorb=N ;;
	esac
	if [ "x${colorf}" != "xN" ] ; then
		tput setaf $colorf
	fi
	if [ "x${colorb}" != "xN" ] ; then
		tput setab $colorb
	fi
	printf "${echo_content}" | sed -e "s/@B/$(tput bold)/g"
	tput sgr 0
	printf "\n"
}

say hello black white
say hello red green
say hello m w
say hello k w
say hello k c
say hello
say hello green
say @Bhello cyan magenta
say hello cyan magenta
