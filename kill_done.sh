#! /bin/bash   
#title           :kill_done.sh
#description     :This script automatically kills done slave jobs on the GRID
#author		     :Gabriele Gaetano Fronzé
#date            :20150303
#version         :0.1    
#usage		     :source resubmit.sh
#notes           :Install Alien to use this script.
#bash_version    :4.2.45(1)-release
#==============================================================================

echo "|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯"
echo "| This script parses a file wich contains job IDs   "
echo "| and kill done slave jobs to free some GRID running quota                   "
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
							alien_ps -b > proc.txt
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
cat $FILEPATH | grep "D" | grep -o '\-[0-9]\{9\}' | cut -c 2- > failedslavejobs.txt

FAILED="$(grep -c ^ failedslavejobs.txt)"

if [[("$FAILED" == 0)]]; then
	echo "|"
	echo "|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯"
	echo "| The script has nothing to do, everything is fine with your jobs!"
	echo "|________________________________________________________________________"	

	# clear variables
	unset FILEPATH
	unset COUNT
	unset FAILED

	return 4
fi

COUNT=0;

# kills slave jobs using alien_kill
while read line; do 
	alien_kill "$line"
	#echo "$line"
	let "COUNT++"
done < failedslavejobs.txt

echo "|"
echo "| Removing dummy files"

# removes files used for list creation
if [[("$AUTOFLAG" == 1)]]; then
	rm proc.txt
fi
rm failedslavejobs.txt

echo "|"
echo "|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯"
echo "| The script has successfully killed $COUNT/$FAILED slave jobs"
echo "|________________________________________________________________________"

# clear variables
unset FILEPATH
unset JQUOTA
unset JQUOTAMAX
unset COUNT
unset FAILED

return 5
