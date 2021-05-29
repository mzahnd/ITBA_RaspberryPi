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
# Only createImages function should be called from parent script.

# To avoid sourcing twice
createImage_sh=1

# Functions in this script:
# NOTE: Functions not listed here are in the parent script (cloner.sh) because
#     another child uses (or could use) them as well
#
# createImages
# _setImageName
# _askImgPath
# _askImgName

# Create an image using an existing Micro SD Card and shrink it
# afterwards.
#
# User is asked to insert a Micro SD Card (see getMicroSD function) and then
# where (s)he would like to save the image file (see _setImageName function).
# After validating this data, the uSD is dd with a block size of 512 
# (dd bs=512...) and shrinked. 
#
# Note that the shrinked image replaces the non shrinked one and a log is
# stored of the shrinking process.
#
# Uses PiShrink script in SCRIPT_PATH[PISHRINK]_PATH to shrink the image.
#
# Arguments: None
# Return:
# 0 Success
# 1 Error
function createImages()
{
    local uSDSize=0
    local freeSpace=0

    # Get Micro SD to clone
    getMicroSD

    # Check for errors 
    if [ $? -ne 0 ] || [ ${MICROSD_PATH} = "" ] || [ ${MICROSD_SIZE} = 0 ]
    then
        >&2 echo -e "${red}Error getting Micro SD Card information.${rmColor}"
        return 1
    fi

    # Get store path
    _setImageName

    # Check for errors
    if [ $? -ne 0 ] || [ ${IMG_PATH} = "" ]; then
        >&2 echo -e "${red}Path to store image was not properly set.${rmColor}"
        return 1
    fi

    # Create image
    local uSDSize_HU=$(devGetSize ${MICROSD_PATH} "HU")
    local ASKcontinue=""

    echo ""
    # Ask for confirmation
    until [[ "${ASKcontinue,,}" = "y" || "${ASKcontinue,,}" = "n" ]]; do
        echo -en "The Micro SD Card in ${bold}${MICROSD_PATH}${rmBold}"
        echo -en " with size ${bold}${uSDSize_HU}${rmBold} "
        echo -en "will be copyed as ${bold}${IMG_PATH}${rmBold} and then "
        echo -e "shrinked."
        echo -en "${lcyan}Are you sure you want to continue? [y/n] "
        echo -en "${rmColor}"

        read ASKcontinue
    done

    if [ "${ASKcontinue,,}" = "n" ]; then
        echo "Returning to main menu."
        return 0
    fi

    # Copy uSD to file
    echo -e "${blue}Copying Micro SD Card to disk...${rmColor}"

    # DBG
    #echo -e "${lyellow}Fake dd${rmColor}"
    #sleep 2
    
    # dd image
    dd bs=512 if=${MICROSD_PATH} of=${IMG_PATH} conv=fsync status=progress
    # Force sync
    sync

    # Shrink image file
    echo -e "${blue}Shrinking image with PiShrink${rmColor}"

    # DBG
    #echo -e "${lyellow}Fake shrink${rmColor}"
    #sleep 2

    # PiShrink must be run as root. So, we've to change the user
    local tmpUsername="${USERNAME}"
    USERNAME="root"
    runScript ${SCRIPT_PATH[PISHRINK]} 2 -ad ${IMG_PATH}

    USERNAME=${tmpUsername}

    # Shrinking finished
    echo -e "${green}Shrinking finished.${rmColor}"
    echo "Image path: ${IMG_PATH}"
    echo "Image size: $(fileGetSize ${IMG_PATH} "HU")"
    echo -e "${blue}Returning to main menu.${rmColor}"

    return 0
}

# Get a valid directory for the image and file name. Appending '.img' 
# at the end of the file.
# Writes to IMG_PATH variable
# Arguments: None
# Return:
# 0 Success
# 1 Fail
function _setImageName()
{
    # Directory to store image file
    local imgDir=""
    # img File name
    local imgFileName=""
    # Free space in the device that contains the direcotry
    local freeDirSpace=0
    # User check
    local ASKUSER_CONTINUE=""

    # Verify that an uSD card has been set already
    if [ ${MICROSD_PATH} = "" ] || [ ${MICROSD_SIZE} = 0 ]; then
        >&2 echo -e "${red}Error getting Micro SD Card information.${rmColor}"
        return 1
    fi

    # Get minumum requiered space
    local requiredFree=$((MICROSD_SIZE*21/10))

    # Prompt user for the directory and image file name
    until [ "${ASKUSER_CONTINUE,,}" = "y" ] || \
        [ "${ASKUSER_CONTINUE,,}" = "yes" ]; do

        # Directory path
        # Only get out of the loop when a directory with enough free
        # space is given
        until [ ${freeDirSpace} -ne 0 ]; do
            # Get desired directory where img file should be stored
            _askImgPath_return=""
            _askImgPath
            imgDir="${_askImgPath_return}"
            
            # Check if there is enough free space
            echo -e "${blue}Calculating free disk space...${rmColor}"
            freeDirSpace=$(dirGetFree ${imgDir})

            if [ ${freeDirSpace} -lt ${requiredFree} ]; then
                >&2 echo -en "${red}There is not enough free space in the "
                >&2 echo -en "given directory. You need more than twice the "
                >&2 echo -e "Micro SD size as free space."
                >&2 echo -e "${lyellow}Free space (in bytes): ${freeDirSpace}"
                >&2 echo -en "Required space (in bytes): "
                >&2 echo -e "${requiredFree}${rmColor}"
                echo ""
                freeDirSpace=0
            else
                echo -en "${green}There is enough free space left in the "
                echo -e "device.${rmColor}"
            fi
        done

        # Get image file name
        if [ "${imgFileName}" = "" ]; then
            _askImgName_return=""
            _askImgName
            imgFileName="${_askImgName_return}"
        fi

        # Get user confirmation
        echo -e "${lcyan}This image will be stored as:${rmColor} "
        echo "${imgDir}${imgFileName}.img"
        echo -e "${lcyan}Do you want to continue? [y/N] ${rmColor}"
        read ASKUSER_CONTINUE

        # In case of a negative answer, clear variables
        if [ "${ASKUSER_CONTINUE,,}" = "n" ] || \
            [ "${ASKUSER_CONTINUE,,}" = "no" ]; then
            imgDir=""
            imgFileName=""
            freeDirSpace=0
        fi
    done

    # Create directory if it doesn't exists
    mkdir -p ${imgDir} &> /dev/null

    # Set image path
    IMG_PATH="${imgDir}${imgFileName}.img"
    return 0
}

# Ask user for a directory to store the image file
# Echoes the image path to variable '_askImgPath_return'
# Arguments: None
# Return:
# 0 Success
function _askImgPath()
{
    # Return string
    _askImgPath_return=""

    local ASKUSER_IMGDIR=""
    
    # Get a full folder path
    while [ "${ASKUSER_IMGDIR}" = "" ]; do
        echo -en "${lcyan}"
        echo -en "In which folder would you like to save the cloned image?"
        echo -e "${rmColor}"
        echo -n "Please enter only the full path to a directory "
        echo "(it does not necessarily have to exist)."

        read ASKUSER_IMGDIR

        # Non full path
        if [ "${ASKUSER_IMGDIR:0:1}" != "/" ]; then 
            >&2 echo -e "${red}Please enter a full path.${rmColor}"
            echo ""
            ASKUSER_IMGDIR=""

        # Append an extra '/' when needed
        elif [ "${ASKUSER_IMGDIR: -1}" != "/" ]; then
            ASKUSER_IMGDIR="${ASKUSER_IMGDIR}/"
        fi
    done

    # Return string in variable
    _askImgPath_return="${ASKUSER_IMGDIR}"

    return 0
}

# Ask user for a image name. Does not append '.img' extension (that's 
# actually done in _setImageName function).
# Echoes the image path to variable '_askImgName_return'
# Arguments: None
# Return:
# 0 Success
function _askImgName()
{
    # Return string
    _askImgName_return=""

    local ASKUSER_IMGFNAME=""

    # Get image name
    while [ "${ASKUSER_IMGFNAME}" = "" ]; do
        echo -en "${lcyan}"
        echo -en "How would you like to call the cloned image?"
        echo -e "${rmColor}"
        echo "Extension '.img' is automatically appended."

        read ASKUSER_IMGFNAME

        if [ "${ASKUSER_IMGFNAME:0:1}" = "/" ]; then 
            ASKUSER_IMGFNAME=$(echo "${ASKUSER_IMGFNAME}" | cut -c 2-)
        fi
    done

    # Return string in variable
    _askImgName_return="${ASKUSER_IMGFNAME}"
    return 0
}
