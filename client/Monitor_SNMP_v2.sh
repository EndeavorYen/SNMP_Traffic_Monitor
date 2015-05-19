#!/bin/bash


###############################################################
########                Version.2                    ##########
###############################################################


###########################
# .3 YELLOW
# .4 RED
# .5 MAX
# .6 GREEN
##########################

VM=SNMP01
COUNTER=0
SUM=0
yellow_alarm=1
red_alarm=1
max_alarm=1
green_alarm=1
Q[0]=0;Q[1]=0;Q[2]=0;Q[3]=0;Q[4]=0;Q[5]=0
x=0
temp=0

# 取得初始值
init(){

	index=$(snmpwalk -v 2c -c public -IR $VM RFC1213-MIB::ifDescr |grep eth0 |cut -d '=' -f 1|cut -d '.' -f 2)
	init_in=$(snmpget -v 2c -c public  -IR -Os $VM IF-MIB::ifInOctets.${index}|cut -d ':' -f 2|tr -d '[:blank:]')
	init_out=$(snmpget -v 2c -c public  -IR -Os $VM IF-MIB::ifOutOctets.${index}|cut -d ':' -f 2 |tr -d '[:blank:]')
	init_total=$[$init_in + $init_out]
}

# 取得目前流量
get_traffic(){

        eth0_in=$(snmpget -v 2c -c public  -IR -Os $VM IF-MIB::ifInOctets.${index}|cut -d ':' -f 2|tr -d '[:blank:]')
        eth0_out=$(snmpget -v 2c -c public  -IR -Os $VM IF-MIB::ifOutOctets.${index}|cut -d ':' -f 2 |tr -d '[:blank:]')
	eth0_total=$[$eth0_in + $eth0_out]
}

# 計算總流量
calculate_traffic(){

	get_traffic

        Q[x]=$[$eth0_total - $init_total + 0]

        # 防止負流量產生
        if [ $[Q[x]] -lt 0 ]; then
                temp=$[4294967295 - $init_total]
                init_total=0
        fi

        Q[x]=$[$eth0_total - $init_total + $temp]

	prev=$[$[$x + 1] % 5]

	SUM=$[$[Q[x]] + $SUM - $[Q[$prev]]]

	echo --------------------------------------------------------------------
        echo 目前流量 = $[$SUM/1048576] MB/min  =  $[$SUM/1073741824] GB/min
	echo --------------------------------------------------------------------

        init_total=$eth0_total
	temp=0
	x=$[$[$x + 1] % 5]
}

# 判斷流量是否超過threshold
threshold_traffic(){

	# 黃色警戒，超過2G #
	if [ $SUM -gt 2147483648 ] && [ $yellow_alarm -eq 1 ]; then
		snmptrap -d -v 2c -c public SNMP-SERVER "" 1.3.6.1.2.1.4.34.1.3.1.4.192.168.1.10 
		yellow_alarm=0

	# 紅色警戒，超過5G #
	elif [ $SUM -gt 5368709120 ] && [ $red_alarm -eq 1 ]; then
		snmptrap -d -v 2c -c public SNMP-SERVER "" 1.3.6.1.2.1.4.34.1.4.1.4.192.168.1.10
		yellow_alarm=0
		red_alarm=0

	# 超過最大流量，8G #
	elif [ $SUM -gt 8589934592 ] && [ $max_alarm -eq 1 ]; then
		snmptrap -d -v 2c -c public SNMP-SERVER "" 1.3.6.1.2.1.4.34.1.5.1.4.192.168.1.10
		yellow_alarm=0
                red_alarm=0
		max_alarm=0

	# 即時流量降至綠色安全範圍，低於2G #
	elif [ $SUM -le 2147483648 ] && [ $yellow_alarm -eq 0 ]; then
		snmptrap -d -v 2c -c public SNMP-SERVER "" 1.3.6.1.2.1.4.34.1.6.1.4.192.168.1.10 
		#green_alarm=1
		yellow_alarm=1
		red_alarm=1
		max_alarm=1

	# 即時流量降至黃色警戒, 低於5G #
	elif [ $SUM -le 5368709120 ] && [ $red_alarm -eq 0 ]; then
                snmptrap -d -v 2c -c public SNMP-SERVER "" 1.3.6.1.2.1.4.34.1.3.1.4.192.168.1.10 
                red_alarm=1
                max_alarm=1

	# 即時流量降至紅色警戒, 低於8G #
        elif [ $SUM -le 8589934592 ] && [ $max_alarm -eq 0 ]; then
                snmptrap -d -v 2c -c public SNMP-SERVER "" 1.3.6.1.2.1.4.34.1.4.1.4.192.168.1.10 
                max_alarm=1
	fi
}


################################# Main Function ###################################

init

while [ $COUNTER = 0 ];do

	# 取得流量並計算 #
	calculate_traffic

	# 判斷是否觸發trap #
	threshold_traffic

	# 固定interval 15s #
	sleep 15
done
