#!/bin/bash
# 	 	Pwdrc 0.0.1
# http://freaknet.org/alpt/src/utils/pwdrc
# 
# This source code is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2 of the License,
# or (at your option) any later version.
#
# (c) Copyright 2005 AlpT (@freaknet.org)
#
# This source file is meant to be sourced by ~/.bashrc
#

IAM=`whoami`
alias_file=".$IAM""_pwdrc"
PWDRC_RECURSE="0"
PWDRC_RECURSE_INDEX="0"

pwdrc_exec_recurse_function() {
	local ii

	for ((ii=1; ii <= $PWDRC_RECURSE_INDEX; ii++))
	do
		if [ "${PWDRC_REC_FUNC_ARRAY[$ii]}" != 0 ]
		then
			# Execute recurse_pwdrc()
			eval "${PWDRC_REC_FUNC_ARRAY[$ii]}"
			recurse_pwdrc
			unset recurse_pwdrc
		fi
	done
}

pwdrc_cdd() {
	local dir_upper_changed

	PWD_NOW=$PWD
	
	[ -z "$1" ] && [ -z "$HOME" ] && cd /
	[ -z "$1" ] && cd "$HOME"
	
	if ! [ -d "$1" -a -x "$1" ]
	then
		cd "$1"
		return $?
	fi
	cd "$1"

	# Check if we walked into a subdir or not
	echo `pwd` | grep -q "^${PWDRC_OLD_PWD[$PWDRC_RECURSE_INDEX]}"
	dir_upper_changed=$?

	if [ "$dir_upper_changed" == 0 ]
	then
		pwdrc_exec_recurse_function
	elif [ "${PWDRC_RECURSE_ARRAY[$PWDRC_RECURSE_INDEX]}" == 0 -o\
		"$dir_upper_changed" == 1 ]
	then
		if [ "${PWDRC_CLOSE_ARRAY[$PWDRC_RECURSE_INDEX]}" != "0" ]
		then
			# execute close_pwdrc()
			eval "${PWDRC_CLOSE_ARRAY[$PWDRC_RECURSE_INDEX]}"
			close_pwdrc
			unset close_pwdrc
			PWDRC_RECURSE="0"
			PWDRC_CLOSE_ARRAY[$PWDRC_RECURSE_INDEX]="0"
		fi

		if [ "$dir_upper_changed" == 1 ]
		then
			PWDRC_OLD_PWD[$PWDRC_RECURSE_INDEX]=""
			PWDRC_RECURSE_ARRAY[$PWDRC_RECURSE_INDEX]=""
			PWDRC_CLOSE_ARRAY[$PWDRC_RECURSE_INDEX]=""
			PWDRC_REC_FUNC_ARRAY[$PWDRC_RECURSE_INDEX]=""
			((PWDRC_RECURSE_INDEX--))

			pwdrc_exec_recurse_function
		fi

	fi

	if [ -f "$alias_file" ]
	then
		user_perm=`stat -c "%U %a" $alias_file`
		if [ "$user_perm" == "$IAM 600" -o \
			"$user_perm" == "$IAM 500" -o\
			"$user_perm" == "$IAM 400" ]
		then	
			unset PWDRC_RECURSE
			. $alias_file
			[ -z "$PWDRC_RECURSE" ] && PWDRC_RECURSE="0";
		
			if [ "$PWD" != "${PWDRC_OLD_PWD[$PWDRC_RECURSE_INDEX]}" ]
			then
				((PWDRC_RECURSE_INDEX++))
				PWDRC_OLD_PWD[$PWDRC_RECURSE_INDEX]="`pwd`"
				PWDRC_RECURSE_ARRAY[$PWDRC_RECURSE_INDEX]="$PWDRC_RECURSE"

				if declare -f close_pwdrc > /dev/null
				then
					PWDRC_CLOSE_ARRAY[$PWDRC_RECURSE_INDEX]="`declare -f close_pwdrc`"
				else
					PWDRC_CLOSE_ARRAY[$PWDRC_RECURSE_INDEX]="0"
				fi

				if declare -f recurse_pwdrc > /dev/null
				then
					PWDRC_REC_FUNC_ARRAY[$PWDRC_RECURSE_INDEX]="`declare -f recurse_pwdrc`"
					# execute recurse_pwdrc()
					recurse_pwdrc
					unset recurse_pwdrc
				else
					PWDRC_REC_FUNC_ARRAY[$PWDRC_RECURSE_INDEX]="0"
				fi
			fi
		fi
	fi
}

cdd() {
	[ -z "$1" ] && [ -z "$HOME" ] && cd /
	[ -z "$1" ] && cd "$HOME"
	cd "$1"
}

alias cd="pwdrc_cdd"

# if there's a pwdrc script in ~/ excute it when we login
cd .
