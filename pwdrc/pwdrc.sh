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
pwdrc_recurse="0"
pwdrc_recurse_idx="0"

pwdrc_exec_recurse_function() {
	local ii

	for ((ii=1; ii <= $pwdrc_recurse_idx; ii++))
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
	local still_in_subdir

	PWD_NOW=$PWD
	
	[ -z "$1" ] && [ -z "$HOME" ] && cd /
	[ -z "$1" ] && [ "$HOME" ] && cd "$HOME"
	
	if ! [ -d "$1" -a -x "$1" ]
	then
        # fallback to cd
		cd "$1"
		return $?
	fi

	cd "$1"

	# Check if we walked into a subdir or not
	echo $PWD | grep -q "^${pwdrc_old_pwd[$pwdrc_recurse_idx]}"
	still_in_subdir=$?

	if [ "$still_in_subdir" == 0 ]
	then
		pwdrc_exec_recurse_function
	elif [ "${pwdrc_recurse_array[$pwdrc_recurse_idx]}" == 0 ]
	then
		if [ "${pwdrc_close_array[$pwdrc_recurse_idx]}" != "0" ]
		then
			# execute close_pwdrc()
			eval "${pwdrc_close_array[$pwdrc_recurse_idx]}"
			close_pwdrc
			unset close_pwdrc
			pwdrc_recurse="0"
			pwdrc_close_array[$pwdrc_recurse_idx]="0"
		fi

		if [ "$still_in_subdir" == 1 ]
		then
			pwdrc_old_pwd[$pwdrc_recurse_idx]=""
			pwdrc_recurse_array[$pwdrc_recurse_idx]=""
			pwdrc_close_array[$pwdrc_recurse_idx]=""
			PWDRC_REC_FUNC_ARRAY[$pwdrc_recurse_idx]=""
			((pwdrc_recurse_idx--))

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

			unset pwdrc_recurse
            
            # source the pwdrc script in the current directory
			. $alias_file

			[ -z "$pwdrc_recurse" ] && pwdrc_recurse="0";
		
			if [ "$PWD" != "${pwdrc_old_pwd[$pwdrc_recurse_idx]}" ]
			then
				((pwdrc_recurse_idx++))
				pwdrc_old_pwd[$pwdrc_recurse_idx]="$PWD"
				pwdrc_recurse_array[$pwdrc_recurse_idx]="$pwdrc_recurse"

				if declare -f close_pwdrc > /dev/null
				then
					pwdrc_close_array[$pwdrc_recurse_idx]="`declare -f close_pwdrc`"
				else
					pwdrc_close_array[$pwdrc_recurse_idx]="0"
				fi

				if declare -f recurse_pwdrc > /dev/null
				then
					PWDRC_REC_FUNC_ARRAY[$pwdrc_recurse_idx]="`declare -f recurse_pwdrc`"
					# execute recurse_pwdrc()
					recurse_pwdrc
					unset recurse_pwdrc
				else
					PWDRC_REC_FUNC_ARRAY[$pwdrc_recurse_idx]="0"
				fi
			fi
        else
            echo Warning: wrong permission on "$alias_file". Group and Others must have 0 permissions. For example, do chmod 600 $(printf '"%s"' "$alias_file").
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
