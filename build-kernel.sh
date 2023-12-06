#!/usr/bin/env bash 

#############################################################################
###########################################################################
###
### Modified/Rewritten by A.M.Danischewski (c) 2015 v1.1
### Issues: If you find any issues emai1 me at my <first name> dot 
###         <my last name> at gmail dot com.  
###
### Based on scripts posted by Pez Cuckow, William Pursell at:  
### http://stackoverflow.com/questions/12498304/using-bash-to-display-\
###      a-progress-working-indicator
###
### This program runs a program passed in and outputs a timing of the 
### command and it exec's a new fd for stdout so you can assign a 
### variable the output of what was being run. 
### 
### This is a very new rough draft but could be expanded. 
### 
### This program is free software: you can redistribute it and/or modify
### it under the terms of the GNU General Public License as published by
### the Free Software Foundation, either version 3 of the License, or
### (at your option) any later version.
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.
###
### You should have received a copy of the GNU General Public License
### along with this program.  If not, see <http://www.gnu.org/licenses/>.
###########################################################################
#############################################################################

#shift      ## Clip the first value of the $@, the rest are the options. 
declare    CMD_OUTPUT=""
declare    TMP_OUTPUT="/tmp/_${0##*/}_$$_$(date +%Y%m%d%H%M%S%N)" 
declare -r SPIN_DELAY="0.1"
declare -i PID=

function usage() {
cat <<EOF

Description: ${0##*/}

This program runs a program passed in and outputs a timing of the 
command and it exec's a new fd for stdout so you can assign a variable 
the output of what was being run. 

Usage: ${0##*/} <command> [command options]

 E.g.  
    >$ ${0##*/} sleep 5 \&\& echo "hello" \| figlet
     Running: sleep 5 && echo hello | figlet, PID 2587:/

     real   0m5.003s
     user   0m0.000s
     sys    0m0.002s
      _          _ _       
     | |__   ___| | | ___  
     | '_ \ / _ \ | |/ _ \ 
     | | | |  __/ | | (_) |
     |_| |_|\___|_|_|\___/ 

     Done..
    >$ var=\$(${0##*/} sleep 5 \&\& echo hi)
     Running: sleep 5 && echo hi, PID 32229:-
     real   0m5.003s
     user   0m0.000s
     sys    0m0.001s
     Done..
     >$ echo \$var
     hi

EOF
} 

function spin_wait() { 
	local -a spin 
	spin[0]="-"
	spin[1]="\\"
	spin[2]="|"
	spin[3]="/"
	echo -en "Running: $1, PID ${PID}: "
	echo ""
	while kill -0 ${PID} 2>/dev/random; do
		for i in "${spin[@]}"; do
			echo -ne "\b$i" 
			sleep ${SPIN_DELAY}
		done
	done
} 

function run_cmd() { 
	eval "$1" 1>>/dev/null & 
	PID=$! # Set global PID to process id of the command we just ran. 
	spin_wait "$1"
	echo ""
	echo  "Done.."
} 

function generate_dtb() {
	if [ $1 = "arm64" ]; then 
		run_cmd "make ARCH=$1 CROSS_COMPILE=$2 O=$3  M=arch/arm64/boot/dts/hisilicon"
		#run_cmd "make ARCH=$1 CROSS_COMPILE=$2 O=$3  ./hisilicon/hip05-d02.dtb"
	else
		run_cmd "make ARCH=$1 CROSS_COMPILE=$2 O=$3  dtbs"
	fi
}

function build_kernel() {
	run_cmd "make ARCH=$1 CROSS_COMPILE=$2 O=$3  $4"
	run_cmd "make ARCH=$1 CROSS_COMPILE=$2 O=$3  -j64"
	generate_dtb $1 $2 $3 $4
	TIMESTAMP=`date "+%Y%m%d-%H%M%S"`
	run_cmd "make ARCH=$1 CROSS_COMPILE=$2 O=$3  -j64 dtbs_check | tee $3/../dtb_check_$TIMESTAMP.log" 
} 

if [ "$1" = "arm64" ]; then 
	#arm64
	rm -rf $(pwd)/../linux-next.build 
	build_kernel arm64 aarch64-linux-gnu- $(pwd)/../linux-next.build  defconfig
	
	rm -rf $(pwd)/../linux-next.build 
	build_kernel arm64 aarch64-linux-gnu- $(pwd)/../linux-next.build  allmodconfig
else
	#arm32
	rm -rf $(pwd)/../linux-next.build 
	build_kernel arm arm-linux-gnueabihf- $(pwd)/../linux-next.build hisi_defconfig
	
	rm -rf $(pwd)/../linux-next.build 
	build_kernel arm arm-linux-gnueabihf- $(pwd)/../linux-next.build multi_v7_defconfig
fi

exit 0 

