#! /bin/bash

##################################
#    有斷網功能，一分鐘之後回復  #
##################################

if [ "$1" == "SNMP01" ]; then
	if [ "$2" == "YELLOW" ]; then
		sudo cp /var/www/yellow.jpg /var/www/status01.jpg
		sudo cp /var/www/yellow_word.jpg /var/www/word01.jpg
	elif [ "$2" == "RED" ]; then
		sudo cp /var/www/red.jpg /var/www/status01.jpg
		sudo cp /var/www/red_word.jpg /var/www/word01.jpg
	elif [ "$2" == "MAX" ]; then
		sudo cp /var/www/max.jpg /var/www/status01.jpg
		sudo cp /var/www/max_word.jpg /var/www/word01.jpg
		sudo ovs-vsctl del-port br7 tap1
		sleep 60
		sudo ovs-vsctl add-port br7 tap1
	elif [ "$2" == "GREEN" ]; then
                sudo cp /var/www/green.jpg /var/www/status01.jpg
		sudo cp /var/www/green_word.jpg /var/www/word01.jpg
	fi
elif [ "$1" == "SNMP02" ]; then
	if [ "$2" == "YELLOW" ]; then
                sudo cp /var/www/yellow.jpg /var/www/status02.jpg
		sudo cp /var/www/yellow_word.jpg /var/www/word02.jpg
        elif [ "$2" == "RED" ]; then
                sudo cp /var/www/red.jpg /var/www/status02.jpg
		sudo cp /var/www/red_word.jpg /var/www/word02.jpg
        elif [ "$2" == "MAX" ]; then
                sudo cp /var/www/max.jpg /var/www/status02.jpg
		sudo cp /var/www/max_word.jpg /var/www/word02.jpg
		sudo ovs-vsctl del-port br7 tap2
                sleep 60
                sudo ovs-vsctl add-port br7 tap2
	elif [ "$2" == "GREEN" ]; then
                sudo cp /var/www/green.jpg /var/www/status02.jpg
		sudo cp /var/www/green_word.jpg /var/www/word02.jpg

        fi

fi
