#!/bin/ksh

#
# Original script from Peter Hessler via Pamela Mosiejczuk
#
# Heavily modified to "de-magic" the color strings and add more comments
#

# WiFi interface
WIFI="iwn0"

# Wired Interface
WIRED="em0"

# Set this to the trunk interface if you are using the trunk wired/wifi trick
TRUNK="trunk0"

# Lemonbar magic strings for color
BACKGROUND="%{B#000000}" # Black
RED="%{F#FF0000}${BACKGROUND}"
GREEN="%{F#00FF00}${BACKGROUND}"
YELLOW="%{F#FFFF00}${BACKGROUND}"
ORANGE="%{F#FFA500}${BACKGROUND}"
COLOROFF="%{F-}%{B-}"

# Magic hex characters to put the degrees symbol plus C for celsius
DEGCELSIUS="°C"

function Battery {
	ADAPTER=$(/usr/sbin/apm -a)
	BPERCENT=$(/usr/sbin/apm -l)
	BMINUTES=$(/usr/sbin/apm -m)
	CHARGING=$(sysctl -n hw.sensors.acpibat0.raw0 | awk '{print $1}')

	if [ ${ADAPTER} = 0 ] ; then
		print -pn "batt: "
	elif [ ${ADAPTER} = 1 ] ; then
		print -pn "AC: "
	else
		print -pn "AC: "
	fi
	if [ ${BPERCENT} -gt 75 ] ; then
		print -pn "${GREEN}${BPERCENT}%%${COLOROFF}"
	elif [ ${BPERCENT} -gt 50 ] ; then
		print -pn "${YELLOW}${BPERCENT}%%${COLOROFF}"
	elif [ ${BPERCENT} -gt 25 ] ; then
		print -pn "${ORANGE}${BPERCENT}%%${COLOROFF}"
	else
		if [ $CHARGING = 2 ]; then
			print -pn "${BPERCENT}%%"
		else
			print -pn "${RED}%{R}${BPERCENT}${BATTERY}%%${COLOROFF}"
		fi
	fi
	[[ "${BMINUTES}" != "unknown" ]] && print -pn \
		" ($((${BMINUTES} / 60))h$((${BMINUTES} % 60))m)${COLOROFF}"
	[[ ${CHARGING} = 2 ]] && print -pn " ${COLOROFF}charging"
}

function Clock {
	local DATETIME=$(date "+%a %F %H:%M %Z")
	print -pn "${COLOROFF}${DATETIME}"
}

function Cpu {
	set -A cpu_values $(iostat -C | sed -n '3,3p')
	local CPULOAD=$((100-${cpu_values[5]}))
	local CPUTEMP=$(sysctl -n hw.sensors.cpu0.temp0 | awk -F. '{print $1'})
	if [ ${CPULOAD} -ge 90 ] ; then
		print -pn "${RED}"
	elif [ ${CPULOAD} -ge 80 ] ; then
		print -pn "${YELLOW}"
	else
		print -pn "${GREEN}"
	fi
	print -pn "CPU: ${COLOROFF}${CPUTEMP}${DEGCELSIUS}"
}

function Load {
	local SYSLOAD=$(systat -b | awk 'NR==3 { print $4" "$5" "$6 }')
	print -pn "Load: ${SYSLOAD}"
}

function Display {
	local LIGHT=$(xbacklight | awk -F. '{print $1'})
	print -pn "Display: ${LIGHT}%%"
}

function Music {
	local STATUS=$(/usr/local/bin/mpc | sed -n '2p' | grep -c paused)
	local SONG=$(/usr/local/bin/mpc current -f '%artist% - %title%')
	print -pn "%{A:/usr/local/bin/mpc -q toggle:}"
	print -pn "%{A3:/usr/local/bin/mpc -q next:}"
	if [ "$STATUS" -eq "0" ]; then
		if [ -z "$SONG" ]; then
			print -pn "Music Stopped"
		else
			print -pn "Now Playing: ${SONG}"
		fi
	else
		print -pn "Paused: ${SONG}"
	fi
	print -pn "%{A}"
	print -pn "%{A}"
}

function Volume {
	local MUTE=$(mixerctl outputs.master.mute | awk -F '=' '{ print $2 }')
	local SPK="$(($(mixerctl outputs.master | awk -F '(=|,)' '{ print $2 }')*100/255))%%"
	if [ "${MUTE}" = "on" ] ; then
		SPK="mute"
	else
		print -pn "${GREEN}"
	fi
	print -pn "Vol:${COLOROFF} ${SPK}"
}

i=0
_w=""

function Weather {
	if [ "$(($i % 20))" = "0" ]; then
		_w=$(/usr/local/bin/ansiweather -a false 2>/dev/null)
		[[ $? != 0 ]] && _w=" No Weather Report"
		i=0
	fi
	let i++

	print -pn "${_w# }"
}

function Wlan {
	local WLANSTAT=$(ifconfig ${WIFI} | awk '/status:/ { print $2 }')
	local WLANID=$(ifconfig ${WIFI}  | \
		awk -F '(nwid |join | chan)' '/(nwid|join)/ { print $2 }' )
	local WLANSIG=$(ifconfig ${WIFI} | grep ieee80211 | \
		awk 'match($0, /-[0-9]*dBm/) \
		{ print substr($0, RSTART, RLENGTH) }')

	print -pn "WLAN: "
	if [ "${WLANSTAT}" = "active" ] ; then
		print -pn "${GREEN}"
	else
		print -pn "${RED}"
	fi
	print -pn "${WLANID} "
	if [ "${WLANSTAT}" = "active" ] ; then
		print -pn -- "${WLANSIG}"
	else
		print -pn "offline"
	fi
	print -pn "${COLOROFF}"
}

function Wired {
	print -pn "Network: wired"
}

function Network {
	# find the ports in the trunk and the interface labelled as active
	local ACTIVE_IFACE=$( ifconfig $TRUNK | grep port | grep active \
		| awk '{ print $1 }' )
	if [ x$ACTIVE_IFACE = x$WIRED ] ; then
		Wired
	elif [ x$ACTIVE_IFACE = x$WIFI ] ; then
		Wlan
	else
		print -pn "Network: ${YELLOW}Unknown${COLOROFF}"
	fi
}

# Start lemonbar as a corprocess
# - Make its X name "lemonbar"
# so the window manager can be configured to skip putting a border on it
lemonbar -n lemonbar |&

# Main information loop feed to lemonbar
while true ; do
	# Look for restart file
	if [ -O ~/.newbar ] ; then
		rm ~/.newbar
		exec $0
	fi
	# Left-justify this group
	print -pn "%{l}"

	Clock
	print -pn " | "

	Battery
	print -pn " | "

	Cpu
	print -pn " | "

	#Load
	#print -pn " | "

	Weather

	# The rest are right-justified
	print -pn "%{r}"

#	Music
#	print -pn " | "

	Volume
	print -pn " | "

	Display
	print -pn " | "

	Network
	print -p ""

	# Wait 5 seconds between updates
	sleep 5

	#### Put read/eval part here? Is there nonblocking read?
done
#done | lemonbar -d -n lemonbar | while read line; do eval "$line"; done
