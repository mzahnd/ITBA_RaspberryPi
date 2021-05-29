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




# Modify hotspot name in hostapd.conf file
# Arguments:
# 1.- Must be set to 0 or 1. This argument indicates that the asked or written 
#    SSID must replace (1) or not (0) the one in the hostapd.conf file.
# 2.- New SSID name. If this parameter is empty (""), the script will ask for
#    an SSID to the user. Otherwise, it must start with a letter or a number
#    and can only contain '-' '_' '.' and ' ' as special characters.
# 3.- Path to hostapd.conf file. If argument 1 is set to 0, this argument is 
#    ignored (it can be replaced with ""); otherwise it must be a valid file
#    with size greater than zero.
# 4.- File to store the asked/writted SSID in hostapd.conf. When setting the
#    first argument as 0, this argument must be a valid file (preferably 
#    empty as it will be overwrited).
#
# Calling examples:
#  Note that this script must be run as root in order to modify the MicroSD
#  files. When only asking for an SSID, this is not necessary (neither 
#  recommended).
# 
#  Objective: Ask for a SSID but do not modify hostapd.conf.
#  Command:   /bin/bash changeHostname.sh 0 "" "" /path/to/empty/file
#  After: File in /path/to/empty/file will be overwrited with the entered SSID.
#
#  Objective: Ask for a SSID and store it in hostapd.conf.
#  Command:   /bin/bash changeHostname.sh 1 "" "/path/to/hostapd" ""
#  After: In File hostapd, the line starting with "ssid=" will be overwrited
#        with "ssid=" + the entered SSID.
#
#  Objective: Modify SSID with a given one in hostapd.conf and store a copy of
#            the used SSID in a file.
#  Command:   /bin/bash changeHostname.sh 1 "MyNewSSID" "/path/to/hostapd" \
#             "/path/to/file"
#  After: In File hostapd, the line starting with "ssid=" will be overwrited
#        with "ssid=MyNewSSID" and file in /path/to/file wil be overwrited
#        with MyNewSSID.
#
#
#
# Functions in this script:
# modifyHotspotName
# _checkFileWithMsg
# _checkSSID
# _askNewSSID
# _checkValidSSID
# _writeData
# _modifyHostapd
# _storeSSID

# Set new SSID to file or not
SET_NEW_SSID="${1}"

# New SSID Name.
GIVEN_SSID="${2}"

# Path to hostapd.conf file
HOSTAPD_PATH="${3}"

# File to save SSID
FILE_SSID_PATH="${4}"

# User-entered SSID
SSID_INPUT=""

# Colors
if [ -z ${_script_colors} ]; then
    source colors.sh
fi

# Get name and path of a given file
if [ -z ${_script_getFilePathName} ]; then
    source getFilePathName.sh
fi

# Check if a file exists, is readable and has size >0
if [ -z ${_script_checkExistence} ]; then
    source checkExistence.sh
fi

# Main function. Verifies that all conditions are met and takes action 
# according to how the script is called.
#
# Arguments: None
# 
# Return:
# 0 Success
# 1 Error
function modifyHotspotName()
{
    local returnVal=-1
    local returnSSID=0
    local modifyHostapd=0

    # DBG
    #echo "SET_NEW_SSID: ${SET_NEW_SSID}"
    #echo "GIVEN_SSID: ${GIVEN_SSID}"
    #echo "HOSTAPD_PATH: ${HOSTAPD_PATH}"
    #echo "FILE_SSID_PATH: ${FILE_SSID_PATH}"


    if [ ${SET_NEW_SSID} -eq 0 ]; then
        # User does not want to set SSID in hostapd, so only returning is 
        # needed

        # Echoes messages on error
        checkFile ${FILE_SSID_PATH}
        if [[ $? -eq 0 || $? -eq 2 ]]; then
            modifyHostapd=0
            returnSSID=1
        else
            echo -en "${red}No path to store SSID file given. Aborting"
            echo -e "${rmColor}"
            returnVal=1
        fi
    else
        # User wants to set SSID, so hostapd.conf file path is needed and
        # return the seted SSID is optional.

        # To modify hostapd file, this script must be run as root
        if [ ${UID} -ne 0 ]; then
            echo -e "${red}Please run this script as root.${rmColor}"
        fi

        # Echoes messages on error
        _checkFileWithMsg ${HOSTAPD_PATH}
        if [ $? -eq 0 ]; then
            # File is valid, we can modify it
            modifyHostapd=1
        else
            # File is invalid. Abort
            returnVal=1
        fi

        # Does not print anything on error as this file is optional.
        checkFile ${FILE_SSID_PATH}
        if [[ $? -eq 0 || $? -eq 2 ]] ; then
            # SSID return wanted
            returnSSID=1
        fi
    fi


    # Check SSID
    if  [ ${returnVal} -ne 1  ]; then
        _checkSSID
        returnVal=$?
    fi

    # Write asked files
    if [ ${returnVal} -ne 1 ]; then
       _writeData ${modifyHostapd} ${returnSSID}
       returnVal=$?
    fi

    return ${returnVal}
}

# Echoes messages on error to sderr.
# 
# Arguments:
# 1.- File to verify
#
# Return:
# 0 Success
# 1 Error
function _checkFileWithMsg()
{
    local returnVal=-1
    local file2Check=${1}

    # Check the file
    checkFile ${file2Check}
    local checkFileReturn=$?

    # Error handler
    if [ -z ${file2Check} ] || [ ${checkFileReturn} -eq -1 ]; then
        # Empty file path
        >&2 echo -e "${red}No valid path to file was given.${rmColor}"
        returnVal=1
    elif [ ${checkFileReturn} -ne 0 ]; then
        # Invalid file
        >&2 echo -en "${red}Invalid file ${file2Check} given. Is the path "
        >&2 echo -en "correct? Is it readable? Does it have something inside "
        >&2 echo -e "(size > 0)?.${rmColor}"
        returnVal=1
    else
        # Everything is fine
        returnVal=0
    fi
    
    return ${returnVal}

}

# Verify if an SSID is valid and ask for one when needed.
# When GIVEN_SSID variable is empty, asks the user for one. In any other
# case, verifies that GIVEN_SSID meets the needed requirements.
#
# Arguments: None
#
# Return:
# 0 SSID is valid
# 1 SSID is not valid
function _checkSSID()
{
    local returnVal=-1

    if [ "${GIVEN_SSID}" = "" ]; then
        # No given SSID? Ask for it
        _askNewSSID
        returnVal=$?
    else
        _checkValidSSID ${GIVEN_SSID}
        if [ $? -ne 0 ]; then
            >&2 echo -en "${red}Invalid SSID. Tthe SSID must start with a "
            >&2 echo -en "letter or a number and the only special characters "
            >&2 echo -e "allowed are .-_ and space.${rmColor}"
            returnVal=1
        else
            returnVal=0
        fi
    fi

    return ${returnVal}
}

# Prompt the user for a new (valid) SSID.
#
# Arguments: None
# Return:
# Stores new SSID in SSID_INPUT variable.
function _askNewSSID()
{
    local validInput=0
    local ssidInput=""

    while [ ${validInput} -eq 0 ]; do
        echo -en "${lcyan}"
        echo -en "Please enter the new SSID: "
        echo -e "${rmColor}"

        read ssidInput

        _checkValidSSID ${ssidInput}
        if [ $? -eq 0 ]; then
            # Valid SSID
            echo "Valid SSID: ${ssidInput}"
            validInput=1
        else
            # Invalid SSID
            >&2 echo -en "${red}Invalid SSID. Tthe SSID must start with a "
            >&2 echo -en "letter or a number and the only special characters "
            >&2 echo -e "allowed are .-_ and space.${rmColor}"
            validInput=0
        fi
    done

    # Store the valid SSID
    SSID_INPUT="${ssidInput}"
}

# Only allow SSIDs starting with a letter or a number and containing ' ', '-',
# '_' and '.' as special characters after the first letter/ number.
#
# Arguments:
# 1.- String with SSID to verify.
#
# Return:
# -1 Empty string as first argument.
# 0 SSID is valid.
# 1 SSID is not valid.
function _checkValidSSID()
{
    if [ -z "${1}" ]; then
        return -1
    elif [[ "${1}" =~ ^[A-Za-z0-9][\ \-\_\.A-Za-z0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Write SSID in its own file and in hostapd.conf as requested.
#
# Arguments:
# 1.- SSID should be written in hostapd.conf
# 2.- SSID shoud be written in its own file.
function _writeData()
{
    local modifyHostapd=${1}
    local returnSSID=${2}
    
    # In hostapd
    if [ ${modifyHostapd} -eq 1 ]; then
        _modifyHostapd
    fi

    # In its own file
    if [ ${returnSSID} -eq 1 ]; then
        _storeSSID
    fi
}

# Perform changes in hostapd.conf file.
# When "ssid=" string exists in hostapd, replace it with "ssid="+desiredSSID.
# In case the line "ssid=" is not in the file, add it.
#
# Arguments: None
#
# Return:
# 0 Success
# 1 Error
function _modifyHostapd()
{
    local stringToReplace="ssid="
    local newString=""
    local regex="^[\ #]*${stringToReplace}.*$"
    
    if [ "${SSID_INPUT}" = "" ]; then
        newString="${stringToReplace}${GIVEN_SSID}"
    else
        newString="${stringToReplace}${SSID_INPUT}"
    fi

    # Check if parameter exists in hostapd.conf
    #echo "Grep: $(grep -E "${regex}" ${HOSTAPD_PATH})"
    grep -E "${regex}" ${HOSTAPD_PATH}
    if [ $? -eq 0 ]; then
        # 'ssid=' exists. Uncomment it if needed and change it
        # Also, creates a backup of the original file
        sed -r --in-place=".bckp" "s/${regex}/${newString}/g" ${HOSTAPD_PATH}
    elif [ $? -eq 1 ]; then
        # No 'ssid=' line in file. Append id
        echo "${newString}" >> ${HOSTAPD_PATH}
    else
        >&2 echo -en "${red}Unknown error while running grep in hostapd.conf "
        >&2 echo -e "file.${rmColor}"
        return 1
    fi

    return 0
}

# Store SSID in its own file (not in hostapd.conf)
#
# Arguments: None
# 
# Return: Nothing
function _storeSSID()
{
    local ssidToStore=""

    if [ "${SSID_INPUT}" = "" ]; then
        ssidToStore="${stringToReplace}${GIVEN_SSID}"
    else
        ssidToStore="${stringToReplace}${SSID_INPUT}"
    fi

    echo "${ssidToStore}" > ${FILE_SSID_PATH}
}

# MAIN
modifyHotspotName
exit $?
