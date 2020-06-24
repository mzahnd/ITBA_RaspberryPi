#!/bin/bash
#
# Copyright 2020 Martin E. Zahnd <mzahnd@itba.edu.ar>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to 
# deal in the Software without restriction, including without limitation the 
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
# sell copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
# THE SOFTWARE.


_FILE_WPASUPPLICANT=${1}

_WIFI_SSID=""
_WIFI_PWD=""

_EMPTY_PWD='(empty password)'

_me=$(basename $0)

# Colors
source colors.sh

function modifyWPA
{
    if [ -z ${_FILE_WPASUPPLICANT} ]; then
        echo -e "${red}Empty file path passed to ${_me}${rmColor}"
    else
        while [ $? -ne 0 ]; do
            _getCreds
        done
        _writeFile
    fi
}

function _getCreds
{
    local validCreds=0
    # Clear credential variables
    _WIFI_SSID=""
    _WIFI_PWD=""

    # Get SSID
    while [ -z ${_WIFI_SSID} ]; do
        echo -en "${lcyan}Insert the desired SSID: ${rmColor}"
        read -p "" _WIFI_SSID
    done

    # Get password
    echo -en "${lcyan}Insert password for ${_WIFI_SSID}: ${rmColor}"
    read -p "" _WIFI_PWD
    
    if [ -z ${_WIFI_PWD} ]; then
        echo -e "${lyellow}No password entered.${rmColor}"
        _WIFI_PWD=${_EMPTY_PWD}
    fi

    validCreds=0
    echo -e "${bold}SSID:${rmBold} ${_WIFI_SSID}"
    echo -e "${bold}Password:${rmBold} ${_WIFI_PWD}"
    while [ ${validCreds} -eq 0 ]; do
        read -p 'Are those credentials correct? [y/n] ' ASK_CREDSOK

        if [ "${ASK_CREDSOK,,}" = "y" ] || [ "${ASK_CREDSOK,,}" = "yes" ]
        then
            validCreds=1
            echo "Writting credentials..."
        elif [ "${ASK_CREDSOK,,}" = "n" ] || [ "${ASK_CREDSOK,,}" = "no" ]
        then
            return 1
        fi
    done

    return 0
}

function _writeFile
{
    # Clear password variable if set to empty password
    if [ "${_WIFI_PWD}" = "${_EMPTY_PWD}" ]; then
        _WIFI_PWD=""
    fi

    # Write file
    if [ ${_WIFI_SSID} ]; then
        echo -n "country=AR " > ${_FILE_WPASUPPLICANT}
        echo "# Codigo del pais ; AR = Argentina" >> ${_FILE_WPASUPPLICANT}
        echo "update_config=1" >> ${_FILE_WPASUPPLICANT}
        echo -n "ctrl_interface=DIR=" >> ${_FILE_WPASUPPLICANT}
        echo -n "/var/run/wpa_supplicant " >> ${_FILE_WPASUPPLICANT}
        echo "GROUP=netdev" >> ${_FILE_WPASUPPLICANT}
        echo "" >> ${_FILE_WPASUPPLICANT}
        echo "network={" >> ${_FILE_WPASUPPLICANT}
        echo "    ssid=\"${_WIFI_SSID}\"" >> ${_FILE_WPASUPPLICANT}
        echo "    psk=\"${_WIFI_PWD}\"" >> ${_FILE_WPASUPPLICANT}
        echo "}" >> ${_FILE_WPASUPPLICANT}

        echo -e "${blue}Wireless credentials successfuly written.${rmColor}"
    else
        echo -e "${red}No SSID in _WIFI_SSID${rmColor}"
    fi
}

modifyWPA
