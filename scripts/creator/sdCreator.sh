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


# 1. Get admin perms
# 2. Get micro sd
# 3. Get image file
# 4. Burn image file
# 5. Check image burning
# 6. Set SSH
# 7. Enable spi ports
# 8. Set WiFi
# 9. Unmount micro sd
# 10. Change script

# Set to avoid running this script directly. It must be run from "runMe.sh"
NOTDIRECTLY=${1}

# Non root user where files can be downloaded and non root commands can be run
USERNAME="${2}"

# Micro SD Card full path
MICROSD_PATH=""

# Image file full path
IMG_PATH=""

# Mount path
MOUNT_PATH=/mnt/rpi_part

# SSH configuration filename
SSH_FILENAME="ssh"

# WPA Supplicant configuration filename
WPA_SUP_FILENAME="wpa-supplicant.conf"

# Micro SD partitions 
# /dev/ path
declare -a uSDpartitions=()
# Where are mounted
declare -A uSDpartitions_mounted=()

# List of auxiliar scripts
SCRIPT_GET_uSD="getMicroSD.sh"
SCRIPT_GET_IMAGE="getImage.sh"
SCRIPT_GET_WIFI="setWiFi.sh"
declare -A SCRIPT_PATH=( \
    ["GETuSD"]="" \
    ["GETIMG"]="" \
    ["SETwIFI"]=""
)

# Colors
if [ -z ${_script_colors} ]; then
    source ../common/colors.sh
fi

# Run a given script with all the desired arguments
if [ -z ${_script_runScript} ]; then
    source ../common/runScript.sh
fi

# Check if it was executed as superuser
function checkSudo
{
    if [ ${UID} -eq 0 ]; then
        echo 0
    else
        echo 1
    fi
}

# I'm not good at ASCII art
function welcomeMessage()
{
    echo "
     ____________    
    |             \  
    |    _____     | 
    |   |     |    | 
    |   |     \    | 
    |   |     _|   | 
    |   |     \    | 
    |   |______|   | 
    |              | 
    |______________| 

    "
}

# Get Micro SD Card path
function getMSD()
{
    # tmp file to store the uSD path
    local uSDFile=/tmp/uSDpath.tmp
    local uSDPath=""

    # Check only requirement
    if [ -z ${USERNAME} ]; then
        >&2 echo -e "${red}Empty username. Aborting.${rmColor}"
        return 1
    fi

    # Create tmp file
    touch ${uSDFile}
    chmod 777 ${uSDFile}

    # Run SCRIPT_PATH[GETuSD] with the 2 needed arguments
    runScript ${SCRIPT_PATH[GETuSD]} 2 ${USERNAME} ${uSDFile}

    # Get information from file
    read -r uSDPath < ${uSDFile}
    
    # Delete file
    rm ${uSDFile}

    # Error
    if [ -z ${uSDPath} ]; then
        >&2 echo -e "${red}Error getting Micro SD card. Aborting${rmColor}"
        return 1
    fi

    # Store uSD path
    MICROSD_PATH="${uSDPath}"
    return 0
}

# Get .img file to burn in the Micro SD card
function getIMG()
{
    # tmp file to store path to .img file
    local imgPathFile=/tmp/imgpath.tmp
    local imgPath=""

    # Check only requirement
    if [ -z ${USERNAME} ]; then
        >&2 echo -e "${red}Empty username. Aborting.${rmColor}"
        return 1
    fi

    # Create tmp file
    touch ${imgPathFile}
    chmod 777 ${imgPathFile}

    # Run SCRIPT_PATH[GETuSD] with the 2 needed arguments
    runScript ${SCRIPT_PATH[GETuSD]} 2 ${USERNAME} ${imgPathFile} |

    # Get information from file
    read -r imgPath < ${imgPathFile}
    
    # Delete file
    rm ${imgPathFile}

    # Error
    if [ -z ${imgPath} ]; then
        >&2 echo -e "${red}Error getting image file. Aborting${rmColor}"
        return 1
    fi

    # Store uSD path
    IMG_PATH="${imgPath}"
    return 0

}

# DD the image in the Micro SD card
function burnIMG
{
    # 
    echo -en "${blue}Prepearing to burn the image (${bold} ${IMG_PATH} "
    echo -e "${rmBold}) in the Micro SD (${bold} ${MICROSD_PATH} ${rmBold} )."
    echo -en "This will take several minutes and little or no output will be "
    echo -en "shown. Please be patient and ${red}DO NOT abort the script."
    echo -e "${rmColor}"

    # Erease card
    # dd bs=1M if=/dev/zero of=${MICROSD_PATH} status=progress
    # Write image
    # dd bs=1M if=${IMG_PATH} of=${MICROSD_PATH} conv=fsync status=progress

    # Check if image was properly burned
    #

    # Sync data
    sync
}

# Mount Micro SD partitions
function mountSD
{
    # DBG
    MICROSD_PATH=/dev/sdb

    # Get Micro SD partitions and store them in an array. At the same time,
    # mount them
    uSDpartitions=()

    echo -en "${blue}Mounting Micro SD partitions... ${rmColor}"

    # Starts in 1 to use #uSDpartitions[@] without decreasing
    let counter=1
    for i in $(lsblk --output NAME --paths --noheadings --list \
        ${MICROSD_PATH}); do
        # Do not store $MICROSD_PATH :)
        if [ ${i} != ${MICROSD_PATH} ]; then
            # Store device partition path in array
            uSDpartitions+=(${i})

            # Mount the partition
            mkdir -p ${MOUNT_PATH}${counter}/
            mount ${i} ${MOUNT_PATH}${counter}/ 2> /dev/null
            
            # Partition properly mounted
            if [ $? -eq 0 ]; then
                # Store mount path in array with [key]=code format
                uSDpartitions_mounted+=( [${i}]="${MOUNT_PATH}${counter}/" )
            fi

            let counter++
        fi
    done

    if [ ${#uSDpartitions_mounted[@]} -eq 0 ]; then
        echo -e "${blue}[ ${red}FAIL${blue} ]${rmColor}"
    else
        echo -e "${blue}[ ${green}OK${blue} ]${rmColor}"
    fi

    echo "Dev path: ${uSDpartitions[@]}"
    echo "Mounted: ${uSDpartitions_mounted[@]}"
    echo "i: "
    for i in ${uSDpartitions_mounted[@]}
    do
        echo ${i}
    done
}

function unmountSD
{
    sync
    for i in ${uSDpartitions_mounted[@]}
    do
        # Unmount suppresing "not mounted" messages
        umount --quiet ${i}

        # When successfuly unmounted, remove the directory
        if [ $? -eq 0 ]; then
            rm -r ${i}
        fi
    done
}

function enableRemoteAccessAndSPI
{
    local bootPartition=$(getBootPartition)

    # Enable SSH
    enableSSH ${bootPartition}

    # Set WiFi credentials
    setWiFi ${bootPartition}

    # Enable SPI Ports
    enableSPI ${bootPartition}
}

# Boot partitions always the contains a "config.txt" file inside, so we look
# for it in every partition
function getBootPartition
{
    # uSDpartitions Paths
    # uSDpartitions_mounted Mounted

    local bootPartition=""
    for i in ${uSDpartitions_mounted[@]}
    do
        # Only the boot partition has a file called "config.txt"
        # Check if the file exists
        checkFile "${i}config.txt"

        # If so, set this one as the boot partition
        if [ $? -eq 0 ]; then
            bootPartition="${i}"
        fi
    done

    echo "${bootPartition}"
}


# Check if a file exists, its size is not zero and is readable.
# Returns 0 if success, 1 otherwise.
# Arguments:
# 1.- Full path to file "/path/to/myfile"
function checkFile
{
    if [ -f ${1} -a -r ${1} -a -s ${1} ]; then
        return 0
    else
        return 1
    fi
}

# Arguments:
# 1.- Path to the boot partition
function enableSSH
{
    # Check that argument has been passed
    if [ -z ${1} ]; then
        echo -e "${red}No boot partitions given${rmColor}"
    else
        # Create SSH configuration file
        touch ${1}${SSH_FILENAME}
    fi
}

# Arguments:
# 1.- Path to the boot partition
function enableSPI
{
    # Check that argument has been passed
    if [ -z ${1} ]; then
        echo -e "${red}No boot partitions given${rmColor}"
    else
        # config.txt path
        local configFile="${1}config.txt"
        # The # at the beggining 
        local originalString="dtparam=spi="
        local newString="${originalString}on"

        # Sed string originalString and change its value to "on"
        sed -ir \
            "s/^[#]*[\ ]*${originalString}[a-zA-Z0-9.\ ]*$/${newString}/g" \
            ${configFile}
    fi
}

# Arguments:
# 1.- Path to the boot partition
function setWiFi
{
    # Check that argument has been passed
    if [ -z ${1} ]; then
        echo -e "${red}No boot partitions given${rmColor}"
        return 1
    fi

    local wpaConf=${1}${WPA_SUP_FILENAME}

    # Create the wpa_supplicant configuration file
    touch ${wpaConf}
    chmod 777 ${wpaConf}

    # Make script executable
    chmod +x ${SCRIPT_GET_WIFI}

    # Insert SSID and password in it
    /bin/bash ${SCRIPT_GET_WIFI} ${wpaConf}
}

# MAIN
# Check that the script is not being run directly
if [ "${NOTDIRECTLY}" != "1" ]; then
    echo -en "${red}Please do not run this script directly but through "
    echo -e "runMe.sh${rmColor}"
    exit 1
fi

# Check root privileges
if [ $(checkSudo) -ne 0 ]; then
    echo -e "${red}Please run the script as root.${rmColor}"
    exit 1
fi

# Welcome message
welcomeMessage

# Remove when finished
echo -e "${yellow}Script currently under develpment. Sorry.${rmColor}"

# Get Micro SD Card path
#getMSD
#echo -e "${blue}${bold}Micro SD path set to ${MICROSD_PATH}${rmBold}${rmColor}"

# Get image file
#getIMG
#echo -e "${blue}${bold}IMG path set to ${IMG_PATH}${rmBold}${rmColor}"

# Burn image to Micro SD Card
#burnIMG

# Mount partitions 
#mountSD

# Enable SSH, SPI port and set WiFi credentials
#enableRemoteAccessAndSPI

# Unmount partitions
#unmountSD

# Change to in-RPi script

exit 0
