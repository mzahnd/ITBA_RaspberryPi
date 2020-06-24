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


# This file is meant to be sourced in its parent (cloner.sh). It's kept 
# separated to improve readability
# Only burnImageinSD function should be called from parent script.

# To avoid sourcing twice
burnImageinSD_sh=1

# Functions in this script:
# NOTE: Functions not listed here are in the parent script (cloner.sh) because
#     another child uses (or could use) them as well
#
# burnImageinSD
# _burnImgInMultiuSDs

# User given SSID prefix to modify hostpot name in image
SSID_PREFIX=""
# Counter as suffix
SSID_COUNTER=0

# dd an image file in one or more uSD card(s). Even "at the same time".
# Only one instance of dd is called at the same time, but, from the user side,
# (s)he does not have to insert another uSD card until the process finishes
# with all the previously inserted. This way, dead times are grouped for the 
# user.
# Arguments: None
# Return:
# 0 Success
# 1 Error
# 2 At least one burning process returned an error. It's up to the user
#  what to do (dd throws error which don't actually matter to the user 
#  sometimes).
function burnImageinSD()
{
    # Total number of uSDs to burn
    local numberSD2Burn=0
    # Number of uSDs that the user wants to burn at the same time
    local numberSDatTime=0

    # Get image with .img extension
    echo -en "${blue}First, we'll get the image file (with '.img' extension)"
    echo -e "${rmColor}"

    getImage

    # Check for errors
    if [ $? -ne 0 ] || [ "${IMG_PATH}" = "" ]; then
        return 1
    fi

    # Explanations for the user
    echo -e "${blue}The selected image file is "
    echo -e "${IMG_PATH}"
    echo -e ""
    echo -en "${lcyan}"
    echo -en "Now you'll will be asked how many Micro SD Cards you want to "
    echo -en "burn using this file and how many of them you can connect at "
    echo -e "the same time in your machine."
    echo -en "If you pick, for example, 2 Micro SD Cards at the same time, "
    echo -en "you'll be asked to insert them one by one and both of them will "
    echo -en "be burn with the image. When that's done, you'll be asked again "
    echo -en "to insert 2 Micro SD Cards (or 1 if an even number of cards "
    echo -e "should be burn) until no more Micro SD Cards are left."
    echo -en "Note that each Micro SD Card will take a certain time to burn "
    echo -en "depending of the type of Card and your disk r/w speed. This a "
    echo -e "boring process indeed."
    echo -e "${rmColor}"

    # Wait for corfirmation
    read -p "Press enter to continue..." DUMMYASK

    # Get number of uSDs the user wants to burn
    while [[ ${numberSD2Burn} =~ '^[0-9]$' || ${numberSD2Burn} -lt 1 ]]; do
        echo -en "${lcyan}"
        echo -en "In how many Micro SD Cards you'd like to burn the image? "
        echo -e "${rmColor}"

        read numberSD2Burn
    done

    # How many uSDs will be connected at the same time
    # The first condition is used to avoid using an if :)
    # Check that the user inputs a number greater than one and smaller than
    # the number of uSDs to burn
    if [ ${numberSD2Burn} -eq 1 ]; then
        numberSDatTime=${numberSD2Burn}
    else
        while [[ ${numberSD2Burn} -gt 1 && \
            (${numberSDatTime} =~ '^[0-9]$' || \
            ${numberSDatTime} -lt 1 || \
            ${numberSDatTime} -gt ${numberSD2Burn}) ]]; do
                echo -en "${lcyan}"
                echo -en "Up to how many Micro SD Cards you will be "
                echo -e "connecting at the same time? ${rmColor}"
    
                read numberSDatTime
        done
    fi
    # DBG
    #echo "numberSDatTime: ${numberSDatTime}"
    #echo "numberSD2Burn: ${numberSD2Burn}"

    # Ask if the hostpot SSID should be changed in every Micro SD Card.
    _askHostapdSSID
    # Set the global counter to 0
    SSID_COUNTER=0
    # There was no thought of any better solution to the previous counter but 
    # a global variable. If you come up with a better idea, I'll like to hear
    # about it.

    # Explanations for the user
    echo -en "${blue}${numberSDatTime} time(s) you'll be asked to unplug any "
    echo -en "Micro SD Card and insert them again in order to properly detect "
    echo -en "them. Please ${bold}only remove those which have not been " 
    echo -e "already detected${rmBold} and leave the rest connected."
    echo -en "You'll be notified when you can remove the pluged card(s)."
    echo -e "${rmColor}"

    # Create counter and error flag
    local counter2Burn=${numberSD2Burn}
    local burnWithErrors=0

    # Loop until all images have been burn
    until [ ${counter2Burn} -eq 0 ]; do
        # _burnImgInMultiuSDs function argument
        local argument=0

        # There are more or an equal number of images left to burn than the
        # number of uSDs that the user plugs at the same time
        if [[ ${numberSDatTime} -gt 0 && \
            ${counter2Burn} -ge ${numberSDatTime} ]]; then
            # Function argument
            argument=${numberSDatTime}
            # Decrease counter variable
            counter2Burn=$((counter2Burn-numberSDatTime))

        # There remain less images to burn than the number of uSDs the user 
        # can plug at the same time
        elif [ ${counter2Burn} -gt 0 ]; then
            # Function argument
            argument=${counter2Burn}
            
            # Clear counter variable
            counter2Burn=0
        fi

        # Call burn images function
        _burnImgInMultiuSDs ${argument}

        echo -en "${blue}Now you can safely remove the already burned Micro "
        echo -e "SD Cards${rmColor}"
        sleep 2
        if [ ${counter2Burn} -gt 0 ]; then
            # Echo the number of uSDs that will be connected at one or the
            # number of remaining uSDs to burn if this one is smaller.
            local remainingCards=0
            if [ ${counter2Burn} -lt ${numberSDatTime} ]; then
                remainingCards=${counter2Burn}
            else
                remainingCards=${numberSDatTime}
            fi

            echo -en "${blue}You'll be now asked to insert ${remainingCards} "
            echo -e "of the remaining Micro SD Cards.${rmColor}"
        fi

        # If at least one error is returned, the echoed message will change
        # later
        if [ ${?} -ne 0 ] && [ ${?} -ne -1 ]; then
            burnWithErrors=1
        elif [ ${?} -eq -1 ]; then
            counter2Burn=0
        fi
    done

    if [ ${burnWithErrors} -eq 0 ]; then
        echo -en "${green}All burning processes finished without error."
        echo -e "${rmColor}"
    else
        echo -en "${lyellow}All burning processes have finished but at least "
        echo -e "one has had problems while burning.${rmColor}"
        return 2
    fi

    return 0
}

# Burns the same image file in IMG_PATH in various Micro SD cards.
# All uSDs are requested to be connected at the same time and be kept
# connected during the whole process.
# Arguments:
# 1.- Number of uSDs that should be connected at the same time.
# Return:
# -1 Invalid number of uSDs (invalid argument)
# 0 Success
# >0 At least one dd command returned >0
function _burnImgInMultiuSDs()
{
    # Number of images to burn at the same time
    local counterAtTime=${1}
    
    # Return value. It's changed to non zero if any burn process returns non 
    # zero.
    local returnStatus=0

    # Path to uSD(s) where the image should be burn
    declare -a _uSDpaths

    # Check for errors
    if [ ${counterAtTime} -le 0 ]; then
        >&2 echo -e "${red}Invalid number of Micro SD cards to burn.${rmColor}"
        return -1
    fi

    # Select uSDs
    _selectMultiuSDs ${counterAtTime}

    # Burn image
    _burnInMultiuSDs
    returnStatus=$?

    
    # If at least one burning failed, an error status is returned
    return ${returnStatus}
}

# Wrapper to select one or more uSDs and store its path in _uSDpaths array
# Arguments:
# 1.- Number of uSDs to select at the time
# Return:
# Nothing
function _selectMultiuSDs()
{
    local counter=${1}
    until [ ${counter} -le 0 ]; do
        # Get uSD
        getMicroSD

        # Check if uSD was properly selected
        if [ -z ${MICROSD_PATH} ]; then
            # Failed selecting uSD
            >&2 echo -e "${red}Error selecting Micro SD Card${rmColor}"
            echo -en "${lcyan}Would you like to try again or skip this "
            echo -e "Micro SD Card? (AGAIN/skip) ${rmColor}"
            read ASK_AGAIN
            if [ ${ASK_AGAIN,,} = "skip" ]; then
                counter=$((--counter))
            fi
        else
            # uSD Selected
            # Add to array
            _uSDpaths+=(${MICROSD_PATH})

            # Decrement counter
            counter=$((--counter))
            # There is still one Micro SD Card to read (at least)
            if [ ${counter} -gt 0 ]; then
                echo -en "${blue}Remember not to unplug any Micro SD Card "
                echo -en "already detected. Just keep unpluged the new one."
                echo -e "${rmColor}"
            fi

        fi
    done
}

# Burn the image in each uSD stored in _uSDpath array.
# When burning is completed, the hostpot name will be tried to be changed,
# without taking into account the dd exit code.
# Arguments: None
# Return:
# 0 dd exit properly and sync command also was successfull
# 1 Either dd or the sync command (after dd) returned an error
function _burnInMultiuSDs()
{
    local ddExitStatus=0

    # Return value. It's changed to non zero if any burn process returns non 
    # zero.
    local returnStatus=0

    for _uSDcard in ${_uSDpaths[@]}; do
        # For preserve dd return value
        ddExitStatus=0

        echo -e "${blue}Starting burning process in ${_uSDcard}...${rmColor}"

        # DBG
        #echo -e "${lyellow}=== Fake burning in ${_uSDcard} ===${rmColor}"
        #sleep 2
        #ddExitStatus=0

        dd bs=512 if=${IMG_PATH} of=${_uSDcard} conv=fsync status=progress
        
        # Preserve exit status
        ddExitStatus=$?
        
        # Force sync
        sync

        if [[ ${?} -eq 0 && ${ddExitStatus} -eq 0 ]]; then
            echo -e "${green}Image properly burn in ${_uSDcard}${rmColor}"
        else
            >&2 echo -en "${red}Burning process returned non zero code for "
            >&2 echo -e "${_uSDcard}"
            if [ ! -z "${SSID_PREFIX}" ]; then
                >&2 echo -en "I will nevertheles try to change the hostpot "
                >&2 echo -e "SSID. Note that this could fail.${rmColor}"
            fi
            returnStatus=1
        fi
        
        # Change hotspot SSID when needed
        if [ ! -z "${SSID_PREFIX}" ]; then
            _getAndEditHostapd ${_uSDcard} 
        fi
    done
}

# Get the hostapd.conf file and modify it.
# This is also a wrapper for all functions related to change the hostapd.conf
# file, as this is the one that actually gets the file path and mounts the 
# partition.
# Arguments:
# 1.- Micro SD path where the hostpot file should be
# Return
# 0 Success
# 1 Error
# -1 Error unmounting partition
function _getAndEditHostapd()
{
    local uSD="${1}"
    # Get uSD full size to avoid reading its value in the following loop
    local uSDSize=$(lsblk --output NAME,SIZE --bytes --paths --noheadings \
        --list --nodeps ${uSD})
    
    local hostapd_path=""
    
    # Get hostapd file
    local partitionPath=""
    local partitionSize=0

    # Get path to partition with the maximum size, as this is the root one. 
    # Ommit uSD, this is the device path and we already have it.
    for i in $(lsblk --output NAME --bytes --paths --noheadings --list ${uSD})
    do
        # Ommit the Micro SD per se 
        if [[ "${i}" != "${uSD}" ]]; then

            # Get size of the current partition
            local tmpSize=$(lsblk --output SIZE --bytes --paths \
                --noheadings --list ${i})

            # And compare it with the latest stored. Whenever the new partition
            # is bigger, store it.
            # The root partition is usually the biggest one
            if [[ ${tmpSize} -ge ${partitionsSize} ]]; then
                partitionSize=${tmpSize}
                partitionPath=${i}
            fi
        fi
    done

    # Check for errors
    if [[ ${partitionSize} -eq 0 || "${partitionPath}" = "" ]]; then 
        >&2 echo -en "${red}Error getting partition with hostapd file. "
        >&2 echo -e "Aborting${rmColor}"
        return 1
    fi

    # Mount partition
    local mountPath=/mnt/rpi_part_root
    mkdir -p ${mountPath}
    mount ${partitionPath} ${mountPath} 2> /dev/null

    # Look for hostapd file
    if [ $? -eq 0 ]; then
        checkFile "${mountPath}/etc/hostapd/hostapd.conf"
        if [ $? -eq 0 ]; then
            hostapd_path="${mountPath}/etc/hostapd/hostapd.conf"
        fi
    fi

    # Error handler
    if [ -z ${hostapd_path} ]; then
        echo -e "${yellow}Error getting hostapd.conf path."
        echo -en "Hotspot SSID in this Micro SD Card will not be "
        echo -e "modified.${rmColor}"
        return 1
    fi
    
    # Modify hostapd file and set the new SSID
    #echo "SSID_COUNTER: ${SSID_COUNTER}"
    SSID_COUNTER=$((SSID_COUNTER+1))
    _modifyHostapdSSID ${SSID_COUNTER} "${hostapd_path}"

    # Sync the modified data into the partition and unmount it
    # The counter is meant to avoid an infinite loop
    local counter=0
    local umountSuccess=1
    until [[ ${umountSuccess} -eq 0 ||  ${counter} -ge 50 ]]; do
        counter=$((counter+1))
        # Sync
        sync
        # Wait in order to ensure that data has been synced
        sleep 1
        # Perform unmount
        umount ${mountPath}
        umountSuccess=$?
    done

    # If the loop overflows and partition could not be unmounted, show an
    # error and keep going.
    if [ ${umountSuccess} -ne 0 ]; then
        >&2 echo -en "${red}Partition ${partitionsPath[${index}]} could not "
        >&2 echo -en "be unmounted. Please try manually unmounting it when "
        >&2 echo -e "the remaining Micro SD Cards have been burned.${rmColor}"
    fi

    # Returns 0 on success or -1 on error (see man umount.2)
    return ${umountSuccess}
}

# Ask user for changing the hostpot SSID
# Arguments:
# None
# Return:
# Always 0
function _askHostapdSSID()
{
    # For keep looping until the user answers the question
    local validAnswer=0
    # User answer (y , yes, n or no)
    local userAns=""

    until [ ${validAnswer} -eq 1 ]; do
        echo -en "${lcyan}Would you like to edit the hostpot SSID of every "
        echo -e "image? (y/n) ${rmColor}"
        echo -en "You'll  be asked for a SSID and it will be added with "
        echo -en "an '_XX' sufix in every card, where XX is an increasing "
        echo -e "number."

        read userAns

        if [[ "${userAns}" = "yes" || "${userAns}" = "y" ]]; then 
            # Get the SSID prefix
            validAnswer=1
            _getHostapdSSID
        elif [[ "${userAns}" = "no" || "${userAns}" = "n" ]]; then 
            # Exit function
            validAnswer=1
        else
            # Ask again
            validAnswer=0
        fi
    done

    return 0
}

# Calls CHANGE_SSID script to get an SSID from user.
# This function does not modifies any file. Only recieves a string (the SSID 
# name) and stores it in SSID_PREFIX.
# Arguments:
# None
# Return:
# 0 Success
# 1 Error
function _getHostapdSSID()
{
    # File to recieve the new SSID
    local ssidFile=/tmp/newSSID.tmp
    local newSSID=""

    # This part of the script must not be run as root
    if [ -z ${USERNAME} ]; then
        >&2 echo -e "${red}Empty username. Aborting.${rmColor}"
        return 1
    fi

    # Create tmp file
    touch ${ssidFile}
    chmod 777 ${ssidFile}

    # Run CHANGE_SSID script with its four arguments
    runScript ${SCRIPT_PATH[CHANGE_SSID]} 4 0 "" "" "${ssidFile}"

    # Get information from file
    read -r newSSID < ${ssidFile}

    # Delete file
    rm ${ssidFile}

    # Error
    if [ -z "${newSSID}" ]; then
        >&2 echo -e "${red}Error getting new SSID. Aborting.${rmColor}"
        return 1
    fi

    # Store new SSID in the global variable
    SSID_PREFIX="${newSSID}"

    return 0
}

# Modifies the SSID in the image using CHANGE_SSID script.
# This is, actually, a wrapper.
# Remember that the hostpot name is always SSID_PREFIX_XX 
# (the SSID entered by the user _ a number from 1 to inf in case there are
# multiple uSDs with the same prefix).
# Arguments:
# 1.- Suffix number for the SSID name
# 2.- Path to hostapd.conf file
# Return:
# 0 Success
# 1 Error
function _modifyHostapdSSID()
{
    # Number to use as suffix in the hostapd.conf file
    local number=${1}
    # Path to file
    local hostapd_path="${2}"
    # Username will be changed in order to run the script as root
    # The non root one is temporaly stored here
    local originalUsername=""

    # This part of the script must be run as root
    if [ -z ${USERNAME} ]; then
        >&2 echo -e "${red}Empty username. Aborting.${rmColor}"
        return 1
    fi

    if [ -z ${hostapd_path} ]; then
        >&2 echo -e "${red}Empty hostapd path. Not modifying file.${rmColor}"
        return 1
    fi

    # Copy the non root username
    originalUsername="${USERNAME}"
    # Trick the script to be run as root
    USERNAME="root"

    # Run CHANGE_SSID script with its four arguments in order to modify
    # hostapd.conf file
    runScript ${SCRIPT_PATH[CHANGE_SSID]} 4 \
        1 "${SSID_PREFIX}_${number}" "${hostapd_path}" ""

    if [ $? -ne 0 ]; then
        # Error
        USERNAME=${originalUsername}
        >&2 echo -e "${red}Error writing new SSID.${rmColor}"
        return 1
    else
        # Hostapd file modified
        USERNAME=${originalUsername}
        echo -e "${green}SSID modified successfuly in hostapd file.${rmColor}"
        return 0
    fi
}


