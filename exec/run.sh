#!/usr/bin/env bash

# script to run the BDE event detection pipeline
# first argument specified scheduled vs single run

echo ">Running BDE Event detection wrapper execution script at mode [$1]."

singleRunModes="news tweets location cluster pipeline"
runscripts=(runNewsCrawling.sh runTwitterCrawling.sh runLocationExtraction.sh runEventClustering.sh   runPipeline.sh)

CRONTAB_PATH="$MOUNT_DIR/bdetab"
export LOG_DIR="/var/log/bde"
mkdir -p "$LOG_DIR"

function usage {
	echo "Module running usage:"
	echo -n "$0 [ $(echo $singleRunModes | sed 's/ / | /g') "
	echo "| cron | ]"
	echo "(The argument is passed along from the driver script)"

}



if [ -z $JARCLASSPATH ]; then
		bash $EXEC_DIR/setClassPath.sh
	export JARCLASSPATH="$(cat $CLASSPATHFILE)"
fi


if [ $# -eq  1 ] ; then
	# provided an argument
	if [ $1 == "help" ]; then
		usage;
		exit 0
	fi
	if [ ! $1 == "cron" ] ; then
		# single run of a single component
		index=0
		for mode in $singleRunModes; do

			if [ "$mode" == "$1" ] ; then 
				bash "$EXEC_DIR/${runscripts[$index]}"
				exit 0
			else
				index=$((index+1))
			fi
		done
		>&2 echo "Undefined argument [$1]."
		usage
		exit 1

	else
		# cronjob run
		echo "Scheduling job according to crontab at [$CRONTAB_PATH]."
		
		if  [ ! -f $CRONTAB_PATH ] ; then
			>&2 echo "No crontab at $CRONTAB_PATH."
			exit 1
		fi
		echo  "Crontab contents are:"
		echo
		cat "$CRONTAB_PATH"
		echo
		echo  "Starting & scheduling."
		service cron start
		crontab $CRONTAB_PATH

		exit 0
	fi
elif [ $# -gt 1 ] ; then
	>&2 echo "$0 needs at most 1 argument."
	usage
	exit 1
else
	# no arguments provided : run whole pipeline once
	echo "Running an one-time instance."
	bash $EXEC_DIR/runPipeline.sh
	echo "Completed."
fi
echo "-Done running BDE Event detection wrapper execution script at mode [$1]."; echo