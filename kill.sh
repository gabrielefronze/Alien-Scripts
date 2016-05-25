#! /bin/bash   
#title           :kill.sh
#description     :This script automatically kill all jobs on the GRID
#author		     :Gabriele Gaetano Fronzé
#date            :20150303
#version         :0.1    
#usage		     :source kill.sh
#notes           :Install Alien to use this script.
#bash_version    :4.2.45(1)-release
#==============================================================================

echo "|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯"
echo "| This script parses a file wich contains job IDs   "
echo "| and kills them                    "
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

# extract master processes
cat $FILEPATH | grep -o '\-[0-9]\{9\}' | cut -c 2- > tokill.txt
cat $FILEPATH | grep -v '\-[0-9]\{9\}' | grep -o '[0-9]\{9\}' > mtokill.txt

MFAILDE="$(grep -c ^ mtokill.txt)"

if [[("$MFAILED" == 0)]]; then
	echo "|"
	echo "|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯"
	echo "| The script has nothing to do, no job has been found!"
	echo "|________________________________________________________________________"	

	# clear variables
	unset FILEPATH
	unset FAILED
	unset MFAILED

	return 4
fi 

COUNT=0
MCOUNT=0

while read line; do 
    alien_kill "$line"
	let "COUNT++"
done < tokill.txt

while read line; do
	alien_kill "$line"
	let "MCOUNT++"
done < mtokill.txt

rm tokill.txt
rm mtokill.txt
if [[("$AUTOFLAG" == 1)]]; then
	rm proc.txt
fi

echo "|"
echo "|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯"
echo "| The script has successfully killed $COUNT jobs"
echo "| and $MCOUNT master processes."
echo "|________________________________________________________________________"

# clear variables
unset FILEPATH
unset MFAILED
unset COUNT
unset MCOUNT
