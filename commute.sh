#!/bin/bash

URL="https://maps.googleapis.com/maps/api/directions/json"
API_KEY="$GOOGLE_MAPS_API_KEY"
origin="Brooklyn"
des="Queens"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


promptOrigin() {
	echo Enter starting point: 
	read origin
	origin=${origin// /+}
}

promptDestination() {
	echo Enter destination:
	read des
	des=${des// /+}
}

apiCall() {
	curl -s "$URL?origin=$origin&destination=$des&departure_time=now&key=$API_KEY" | 
	ruby -rjson -e 'data = JSON.parse(STDIN.read); puts data["routes"][0]["legs"][0]["duration_in_traffic"]["text"]'
}

while getopts ":hm:copt" opt; do
  case ${opt} in
    h ) # help
			printf "Usage: commute [-h] [-m] [-c] [-o] [-d] [-p]\n"
      printf "      -h     Display this help message.\n"
      printf "      -m     Monitor your commute over the amount of MINUTES you enter.\n"
			printf "      -c     Manually enter your origin and destination.\n"
			printf "      -o     Set new origin.\n"
			printf "      -d     Set new destination.\n"
			printf "      -p     See what your origin and destination variables are set to.\n"

      exit 0
      ;;
    m ) # monitor
			mins=$OPTARG
			let "mins *= 60"
			currTraffic=$(apiCall | egrep -o '^([0-9])*')
			printf "I'll monitor traffic for you over the next $OPTARG minutes!\n"
			printf "Your current commute is $currTraffic minutes long.\n\n"
			let "pastTraffic = $currTraffic"
			while :
			do
				# Every minute, make a call to google api to check the current traffic.
				# Print message based on 
				sleep 60
				
				currTraffic=$(apiCall | egrep -o '^([0-9])*')

				if (( currTraffic > pastTraffic ))
				then
					printf "${RED}Traffic is getting worse...${NC}\n"
					printf "Currently: $currTraffic mins.\n\n"
					pastTraffic=$currTraffic
				elif ((currTraffic < pastTraffic))
				then
					printf "${GREEN}Traffic is dying down!${NC}\n"
					printf "Currently: $currTraffic mins.\n\n"
					pastTraffic=$currTraffic
				else
					printf "Traffic is about the same\n"
					printf "Currently: $currTraffic mins.\n\n"
					pastTraffic=$currTraffic
				fi

				if (($SECONDS >= $mins))
				then
					echo "Done monitoring traffic!"
					break
				fi
			done

			exit 0
      ;;
		c ) # custom options
			promptOrigin
			promptDestination
			;;
		o ) # overwrite
			printf "Are you sure you want to overide your starting point? (Y/n)"
			read ans

			if [ $ans = 'Y' ] || [ $ans = 'y' ]
			then
				promptOrigin
				gsed -i -e '0,/origin="'"$origin"'"/ s/origin="'"$origin"'"/origin="'"${newvar// /+}"'"/g' commute.sh
			fi

			printf "Are you sure you want to overide your destination? (Y/n)"
			read ans

			if [ $ans = 'Y'] || [ $ans = 'y' ]
			then
				promptDestination
				gsed -i -e '0,/des="'"$des"'"/ s/des="'"$des"'"/des="'"${newvar// /+}"'"/g' commute.sh
			fi
			
			exit 0
			;;
		p ) # peek
			printf "\n "
			printf "	Origin:	     ${origin//+/ } \n"
			printf "	Destination: ${des//+/ } \n\n"
			exit 0
			;;
    \? ) echo "Usage: commute [-h] [-m] [-c] [-o] [-d] [-p]"
      ;;
  esac
done




# Grabs json with how long the commute would be
commute_mins=$(apiCall | egrep -o '^([0-9])*')


echo "Current commute: $commute_mins"
