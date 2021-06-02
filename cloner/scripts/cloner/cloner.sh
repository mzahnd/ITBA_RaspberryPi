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


# Create an image from a Micro SD Card and shrink it using PiShrink
# or clone an already cloned image in one or more Micro SD Cards at the same
# time.
#
# This script must be run from runMe.sh script as it needs a non root username
# but being run as root.
# It makes use of the following scripts and files:
#
# getMicroSD.sh
# getImage.sh
# pishrink.sh
# colors.sh
# getFilePathName.sh
# runScript.sh
#
# And its children are (files that are sourced because they have a irectly 
# depence with this script).
# burnImageinSD.sh
# createImage.sh
#
# Functions in this script:
# welcomeMessage
# menu
# getMicroSD
# getImage
# devGetSize
# devGetFree
# dirGetFree
# fileGetSize
# checkFile
# checkScript

# Set to avoid running this script directly. It must be run from "runMe.sh"
NOTDIRECTLY=${1}

# Non root user where files can be downloaded, reached or wirted
USERNAME=${2}

declare -A SCRIPT_PATH=( \
# Script tho get a Micro SD Card full path
    ["GETuSD"]="../common/getMicroSD.sh" \
# Script to get an .img file
    ["GETIMG"]="../common/getImage.sh" \
# PiShrink script
    ["PISHRINK"]="pishrink/pishrink.sh" \
# Script to modify hostapd SSID
    ["CHANGE_SSID"]="../common/changeHostname.sh"
)

# Micro SD Card full path
MICROSD_PATH=""

# Micro SD Card size
MICROSD_SIZE=0

# Image file full path
IMG_PATH=""

# Colors
if [ -z ${_script_colors} ]; then
    source ../common/colors.sh
fi

# Get name and path of a given file
if [ -z ${_script_getFilePathName} ]; then
    source ../common/getFilePathName.sh
fi

# Check if a file exists, is readable and has size >0
if [ -z ${_script_checkExistence} ]; then
    source ../common/checkExistence.sh
fi

# Run a given script with all the desired arguments
if [ -z ${_script_runScript} ]; then
    source ../common/runScript.sh
fi

# Welcome message
function welcomeMessage()
{
    # Artist:  Bob Allison
    echo -e "${rmColor}${white}
              __  _
          .-.\'  \`; \`-._  __  _
         (_\,         .-:\'  \`\; \`-.
       ,\'o\"(        (_,            )
      (__,-\'      ,\'o\"(            )>
         (       (__,-\'            )
          \`-\'._.--._(             )
             |||  |||\`-\'._.--._.-\'
     Dolly              |||  |||
    ${rmColor}"
}

# Main Menu
# Create an image from a Micro SD card 
# Create new ones from an image
# Exit
# Return:
# Return value from called function or 0 if exit is called from main menu
function menu()
{
    # Nobody uses -5 as a return value.
    local returnValue=-5
    local ASK=""

    # Display main menu until a return value is given by any selected option
    # (Either on success or failure)
    until [ ${returnValue} -ne -5 ]; do
        echo ""
        echo -ne "${bold}1.${rmBold} Create an image from an existing "
        echo -e "Micro SD Card."
        echo -ne "${bold}2.${rmBold} Burn copies of an existing image in one "
        echo -e "or more Micro SD Cards."
        echo -e "${bold}3.${rmBold} Print the sheeps again, please."
        echo -e "${bold}4.${rmBold} Exit."
        echo -ne "Please enter the desired option: "
        read ASK

        # DBG
        #echo "ASK: ${ASK}"
        case ${ASK} in
            1)
                if [ -z ${createImage_sh} ]; then
                    # Source code
                    source createImage.sh
                fi

                # Call main function
                createImages

                if [ $? -eq 0 ]; then
                    returnValue=-5
                    ASK=""
                else
                    returnValue=$?
                fi
                ;;
            2)
                if [ -z ${burnImageinSD_sh} ]; then
                    # Source code
                    source burnImageinSD.sh
                fi

                # Call main function
                burnImageinSD
                echo -e "${blue}Returning to main menu...${rmColor}"

                if [ $? -eq 0 ]; then
                    returnValue=-5
                    ASK=""
                else
                    returnValue=$?
                fi
                ;;
            3)
                echo "Sure thing!"
                echo ""
                welcomeMessage
                echo ""
                echo "I'm glad that you like them!"
                echo -n "Did you know that Dolly (5 July 1996 – 14 February "
                echo -n "2003) was a female domestic sheep, and the first "
                echo -n "mammal cloned from an adult somatic cell, using the "
                echo "process of nuclear transfer."
                echo "Source: Wikipedia"

                returnValue=-5
                ;;
            4)
                returnValue=0
                ;;
            *)
                echo -e "${red}Invalid option. Please try again.${rmColor}"
        esac
    done

}

# Get a Micro SD Card
# Uses SCRIPT_PATH[GETuSD] script to get it (this is actually a wrapper)
# Writes to MICROSD_PATH and MICROSD_SIZE variables
# Needs a non root username set in USERNAME variable
# Arguments: None
# Return:
# 0 Success
# 1 Error
function getMicroSD()
{
    # tmp file to store the uSD path
    local uSDFile=/tmp/getuSD.tmp
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
    if [ -z "${uSDPath}" ]; then
        >&2 echo -e "${red}Error getting Micro SD Card. Aborting.${rmColor}"
        return 1
    fi

    # Store uSD path and size in bytes
    MICROSD_PATH="${uSDPath}"
    MICROSD_SIZE=$(devGetSize ${uSDPath})

    return 0
}

# Get an existing image (.img) file
# Uses SCRIPT_PATH[GETIMG] script to get it (this is actually a wrapper)
# Writes to IMG_PATH on success
# Needs a non root username in USERNAME variable
# Arguments: None
# Return:
# 0 Success
# 1 Fail
function getImage()
{
    # tmp file to store path to .img file
    local imgPathFile=/tmp/imgpath.tmp
    local imgPath=""

    # Check requirements
    if [ -z ${USERNAME} ]; then
        >&2 echo -e "${red}Empty username. Aborting.${rmColor}"
        return 1
    fi

    # Create tmp file 
    touch ${imgPathFile}
    chmod 777 ${imgPathFile}
    
    # Run script with its three desired args
    runScript ${SCRIPT_PATH[GETIMG]} 3 ${USERNAME} ${imgPathFile} 1
    
    # Get path from script output (tmp file)
    read -r imgPath < ${imgPathFile}
    # Delete tmp file
    rm ${imgPathFile}

    # Error
    if [ -z "${imgPath}" ]; then
        >&2 echo -e "${red}Failed to get image file.${rmColor}"
        return 1
    fi

    # Store .img file path
    IMG_PATH="${imgPath}"

    return 0
}

# Echoes a device size in bytes or "human readable" format
# Arguments:
# 1.- Device path
# 2.- (OPTIONAL) String "HU" to get the device size in "human
#    readable" format. An empty second parameter or with anyting
#    else but a string "HU" will return the size in bytes.
# Return:
# 0 Success
# 1 Empty device path
function devGetSize()
{
    # Used to set size to other but human readable format
    local sizeUnit=""
    # Optional second arg
    local sizeType=${2}

    # First argument must be given
    if [ -z ${1} ]; then
        echo "Empty device path."
        return 1
    fi
    
    # Check for second argument
    case ${sizeType} in
        # Return in human readable
        "HU")
            sizeUnit=""
            ;;
        # Return in bytes
        *)
            sizeUnit="--bytes"
            ;;
    esac

    # Device size
    echo $(lsblk --nodeps --output SIZE ${sizeUnit} --paths \
        --noheadings --list ${1})

    return 0
}

# Echoes free space in a device in bytes or "human readable" format
# Arguments:
# 1.- Device path
# 2.- (OPTIONAL) String "HU" to get the device size in "human
#    readable" format. An empty second parameter or with anyting
#    else but a string "HU" will return the size in bytes.
# Return:
# 0 Success
# 1 Empty device path
function devGetFree()
{
    # Used to store the space size unit (bytes or HU)
    local sizeUnit=""

    # First argument must be given
    if [ -z ${1} ]; then
        echo "Empty device path."
        return 1
    fi
    # Check second argument
    case ${2} in
        # Human readable
        "HU")
            sizeUnit="--human-readable"
            ;;
        # Return in bytes
        *)
            sizeUnit="--block-size=1"
            ;;
    esac

    # Get free space from a device
    echo $(df ${sizeUnit} --output=avail ${1} | \
        awk 'FNR == 2 {print $1}')

    return 0
}

# Given a folder path, echoes free space in the containing device in bytes or 
# "human readable" format
# Arguments:
# 1.- Folder path. Does not have to exists! The function goes up until it finds
#    a folder that does exist.
# 2.- (OPTIONAL) String "HU" to get the device size in "human
#    readable" format. An empty second parameter or with anyting
#    else but a string "HU" will return the size in bytes. 
# Return:
# 0 Success
# 1 Empty directory path
function dirGetFree()
{
    # Folder path
    local path=${1}
    # Size type (for second argument)
    local sizeUnit=""
    # df output is stored here for checking its validity
    local dfOutput=""

    # Folder path must be given
    if [ -z ${path} ]; then
        echo "Empty device path."
        return 1
    else
        # Check second argument
        case ${2} in
            # Human readable
            "HU")
                sizeUnit="--human-readable"
                ;;
            # Return in bytes
            *)
                sizeUnit="--block-size=1"
                ;;
        esac

        # Loop until a dir is reached with a valid path
        until [ "${dfOutput}" != "" ]; do
            # Errors (like "No such file or directory" are discarded)
            # when running df to avoid printing them in the screen
            dfOutput=$(df ${sizeUnit} --output=avail ${path} 2> /dev/null | \
                awk 'FNR == 2 {printf $1}')

            # When an error occured, awk echoes "", so this is what we'll check
            if [ "${dfOutput}" = "" ]; then
                # Remove last directory from the path, as this does not exists
                path=$(dirname ${path})
            fi
        done

        # Return the free space on the device where the directory is/will be
        echo "${dfOutput}"
        return 0
    fi
}

# Echoes file size in bytes or "human readable" format
# Arguments:
# 1.- File path.
# 2.- (OPTIONAL) String "HU" to get the device size in "human
#    readable" format. An empty second parameter or with anyting
#    else but a string "HU" will return the size in bytes.
# Return:
# 0 Success
# 1 Empty file path
# 2 File does not exists
function fileGetSize()
{
    # Size type (for second argument)
    local sizeUnit=""

    # First parameter must not be empty
    if [ -z ${1} ]; then
        echo "Empty file path."
        return 1
    
    # File must exist
    elif [ ! -f ${1} ]; then
        echo "File does not exists."
        return 2
    else
        # Check second argument
        case ${2} in
            "HU")
                sizeUnit="--human-readable"
                ;;
            # Return in bytes
            *)
                sizeUnit="--block-size=1"
                ;;
        esac

        # Echo file size 
        echo $(du ${sizeUnit} ${1} | awk '{print $1}')
        return 0
    fi
}

# Check that all scripts exist
for i in ${SCRIPT_PATH[@]}; do
    # DBG
    #echo "${i}"
    checkFile ${i}
    if [ $? -ne 0 ]; then
        echo -e "${red}Script ${i} not found${rmColor}"
        exit 1
    fi
done

# Check that script is run from runMe.sh
if [[ ${NOTDIRECTLY} -eq 1 && "${USERMANE}" != "root" && ${UID} -eq 0 ]]; then
    welcomeMessage
    menu
else
    echo -e "${red}Script must be called from runMe.sh${rmColor}"
fi
