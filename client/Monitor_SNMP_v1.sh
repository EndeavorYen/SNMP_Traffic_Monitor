#!/bin/bash

# Version.1 #

VM=SNMP01
COUNTER=0
SUM=0
yellow_alarm=1
red_alarm=1
max_alarm=1

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
        PREV_SUM=$SUM
        SUM=$[$eth0_total - $init_total + 0]

        # 防止負流量產生
        if [ $SUM -lt 0 ]; then
                PREV_SUM=$[ 4294967295 - $init_total + $PREV_SUM ]
                init_total=0
        fi

        SUM=$[$eth0_total - $init_total + $PREV_SUM]

	echo --------------------------------------------------------------
        echo 目前流量 = $[$SUM/1048576] MB  =  $[$SUM/1073741824] GB
	echo --------------------------------------------------------------

        init_total=$eth0_total
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
		red_alarm=0

	# 超過最大流量，10G #
	elif [ $SUM -gt 10737418240 ] && [ $max_alarm -eq 1 ]; then
		snmptrap -d -v 2c -c public SNMP-SERVER "" 1.3.6.1.2.1.4.34.1.5.1.4.192.168.1.10
		max_alarm=0
	fi
}


################################# Main Function ###################################

init

while [ $COUNTER = 0 ];do

	# 取得流量並計算 #
	calculate_traffic

	# 判斷是否觸發trap #
	threshold_traffic

	# 固定interval 13s #
	sleep 13
done
