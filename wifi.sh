#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# ./wifi.sh to connect to wireless networks               #
# quicker for new nets and keeps network configs managed  #
# ~~~~~~~~~~~~~~KyleFleming@gmail.com~~~~~~~~~~~~~~~~~~~~~#
if [[ $EUID -ne 0 ]]; then
  echo "Need moar sudo, please" 1>&2
  exit 1
fi
intfc="wlp4s0"    #Change to your interface
homedir="/home/radman"  #Change to your $HOME
if pgrep "wpa_supplicant" > /dev/null
then
  kill -15 $(pgrep wpa_supplicant)
fi
touch $homedir/.wpa/quit
IFS=!
known_loc ()
{
  cd $homedir/.wpa/
  clients=(*)
  echo "Which AP would you like to connect to?"
  select ap in ${clients[@]};
  do
      if [[ $ap == "quit" ]];
      then
        exit 1
      fi
      echo $ap
      echo "Attempting to connect"
      connect $ap
      break
  done
}
create_psk () {
  ssid=$1
  psk=$2
  wpa_passphrase $ssid $psk >$homedir/.wpa/$ssid.cfg
  connect $homedir/.wpa/$ssid.cfg
} &> /dev/null
connect () {
  wpa_supplicant -c $1 -i $intfc -B
  dhcpcd $intfc
} &> /dev/null
nonwpa () {
  iwconfig $intfc essid $1
  dhcpcd $intfc
} &> /dev/nul
fuck_me_its_wep () {
ssid=$1
wep=$2
iwconfig essid $1
iwconfig key $2
iwconfig enc on
dhcpcd $intfc
}
if [[ $1 == "" ]];
then
  known_loc
elif [[ $1 == "--new" ]];
then
  create_psk $2 $3
elif [[ $1 == "--essid" ]];
then
  nonwpa $2
elif [[ $1 == "--wep" ]];
then
  fuck_me_its_wep $2 $3
elif [[ $1 == "--help" ]];
then
  printf "USAGE:\t$0 --new ESSID PSK\tMake ~/.wpa/ESSID.wpa\n"
  printf "\t$0 --essid ESSID \tFor non wpa networks\n"
  printf "\t$0 --wep ESSID KEY \tConnect to wep network\n"
  printf "\t$0\t\t\tSelect AP from menu of AP confs in ~/.wpa\n"

fi
