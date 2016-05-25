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
echo "| This script parses a file wich contains job IDs   "
echo "| and resubmits them to the GRID                    "
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

# resubmits jobs using alien_resubmit until allowed
while read line; do 
	let "JQUOTA++"
	if [ "$JQUOTA" -ge "$JQUOTAMAX" ]; then
		let "COUNT++"
		echo "|"
		echo "| Resubmission stopped due to job quota limit at job $line (n. $COUNT)"
		let "COUNT--"
		break
	fi
	alien_resubmit "$line"
	let "COUNT++"
done < failedslavejobs.txt

# resubmits mster jobs which splitting has gone wrong
while read line2; do 
	alien_resubmit "$line2"
	let "MCOUNT++"
done < failedmasterjobs.txt

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

return 5
