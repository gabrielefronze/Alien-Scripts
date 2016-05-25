#! /bin/bash   
#title           :resubmit.sh
#description     :This script automatically resubmits failed jobs on the GRID
#author		     :Gabriele Gaetano Fronzé
#date            :20150303
#version         :0.1    
#usage		     :source resubmit.sh
#notes           :Install Alien to use this script.
#bash_version    :4.2.45(1)-release
#==============================================================================

echo "|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯"
echo "| WARNING!!! Be sure of what are you doing by running this script:"
echo "|"
echo "| This script parses a file wich contains job IDs   "
echo "| and resubmits jobs in error state to the GRID                    "
echo "|________________________________________________________________________"
echo "|"
echo "|"
# here it simply lists all txt files found in the working directory
echo "| Found txt files are:"
echo "|"
ls -al *.txt
echo "|"
# some variables used later
FILEPATH=""
AUTOFLAG=0
# ask for automatic process list retrievering
read -p                "| Is there the aliensh ps output file? [Y,n]                  " yn
case $yn in
	[Yy]* )
			read -e -p "| Please enter the path to the file:                          " FILEPATH
			;;

	[Nn]* )
			read -p    "| Do you want this script to retrieve this for you? [Y,n]     " yn1
				case $yn1 in
					[Yy]* )
							alien_ps -b -E > proc.txt
							FILEPATH="proc.txt"		
							AUTOFLAG=1	
							;;	
					[Nn]* )
							echo "| Why did you run me?"
							return 2
							;;
					* )
							echo  "| Please use Yes or No."
							return 3
							;;
				esac
			;;
	* ) 
			echo  "| Please use Yes or No."
			return 1
			;;
esac

# extract failed not-master process id
cat $FILEPATH | grep -o '\-[0-9]\{9\}' | cut -c 2- > failedslavejobs.txt
# extract master processes with faulty splitting
cat $FILEPATH | grep " ESP" | grep -o '[0-9]\{9\}' > failedmasterjobs.txt
cat $FILEPATH | grep " EI" | grep -o '[0-9]\{9\}' >> failedmasterjobs.txt
cat $FILEPATH | grep " EXPIRED" | grep -o '[0-9]\{9\}' >> failedmasterjobs.txt

FAILED="$(grep -c ^ failedslavejobs.txt)"
MFAILED="$(grep -c ^ failedmasterjobs.txt)"

if [[("$FAILED" == 0) && ("$MFAILED" == 0)]]; then
	echo "|"
	echo "|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯"
	echo "| The script has nothing to do, everything is fine with your jobs!"
	echo "|________________________________________________________________________"	

	# clear variables
	unset FILEPATH
	unset JQUOTA
	unset JQUOTAMAX
	unset COUNT
	unset MCOUNT
	unset FAILED
	unset MFAILED

	return 4
fi

# retrieves the jqouta from alien in order to avoid over-limit resubmissions
JQUOTA="$($ALICE_PREFIX/alien/api/bin/gbbox 'jquota list gfronze' | grep -o '[0-9]*[0-9]\{2\}/  100' | rev | cut -c 7- | rev)"
echo "|"
echo "| Your actual job quota is: $JQUOTA/100"
JQUOTAMAX=100
COUNT=0
MCOUNT=0

MAXFORKS=0

if [ "$(uname)" == "Darwin" ]; then
    MAXFORKS="$(sysctl hw | grep 'hw.logicalcpu: [0-9]' | grep -o '[0-9]'    )"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	NCPUCORES=0
	THREADSPERCORE=0
	NCPUCORES="$(lscpu | grep 'Core(s) per socket: \+[0-9]$' | grep -o '[0-9]')"
	THREADSPERCORE="$(lscpu | grep 'Thread(s) per core: \+[0-9]$' | grep -o '[0-9]')"
	MAXFORKS=$(($NCPUCORES * $THREADSPERCORE))
	unset NCPUCORES
	unset THREADSPERCORE
fi

NFORKS=0

# resubmits jobs using alien_resubmit until allowed
while read line; do 
	#echo "$line" &
	if (("$NFORKS" >= "MAXFORKS" )); then
		echo "waiting a moment..."
		wait
		NFORKS=0;
	fi
	let "NFORKS++"
	let "JQUOTA++"
	if [ "$JQUOTA" -ge "$JQUOTAMAX" ]; then
		let "COUNT++"
		echo "|"
		echo "| Resubmission stopped due to job quota limit at job $line (n. $COUNT)"
		let "COUNT--"
		break
	fi
	(alien_resubmit "$line" > /dev/null 2>&1 &)
	#echo "$line" &
	let "COUNT++"
done < failedslavejobs.txt
wait

NFORKS=0

# resubmits mster jobs which splitting has gone wrong
while read line2; do 
	#echo "$line" &
	if (("$NFORKS" >= "MAXFORKS" )); then
		echo "waiting a moment..."
		wait
		NFORKS=0;
	fi
	let "NFORKS++"
	(alien_resubmit "$line2" > /dev/null 2>&1 &)
	#echo "$line" &
	let "MCOUNT++"
done < failedmasterjobs.txt
wait

echo "|"
echo "| Removing dummy files"

# removes files used for list creation
if [[("$AUTOFLAG" == 1)]]; then
	rm proc.txt
fi
rm failedslavejobs.txt
rm failedmasterjobs.txt

echo "|"
echo "|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯"
echo "| The script has successfully resubmitted $COUNT/$FAILED slave jobs"
echo "| and $MCOUNT/$MFAILED master processes with faulty splitting."
echo "|________________________________________________________________________"

# clear variables
unset FILEPATH
unset JQUOTA
unset JQUOTAMAX
unset COUNT
unset MCOUNT
unset FAILED
unset MFAILED
unset MAXFORKS
unset NFORKS

return 5