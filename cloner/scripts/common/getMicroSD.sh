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


# ==== IMPORTANT! READ FIRST ====
# Run this script from another one like this:
#
#   USERNAME="somenonrootusername"
#   # Temporal file
#   local uSDFile=/tmp/getuSD.tmp
#   # Create it and give it rw permission
#   touch ${uSDFile}
#   chmod 777 ${uSDFile}
#   # Call this script as non root
#   sudo -u ${USERNAME} /bin/bash ./getImage.sh ${USERNAME} ${uSDFile}
#   # Read file and remove it. Stores the path in uSD_PATH variable
#   read -r uSD_PATH < ${uSDFile}
#   rm ${uSDFile}
#
#
# Make sure you get a valid username for the corresponding variable.
# 


# Non root user where files can be downloaded if needed
_USERNAME=${1}

# Path where IMA_PATH final path must be written
_OUTPUT_PATH=${2}

declare -a detected_devs
_MICROSD_PATH=""

# Script filename
_me=$(basename $0)

# Colors
if [ -z ${_script_colors} ]; then
    source colors.sh
fi

# This is the function that should be called from another file
function getSDCardPath
{
    if [ -z ${_USERNAME} ] || [ ${_USERNAME} = "root" ] || [ ${UID} -eq 0 ]
    then
        echo -e "${red}Invalid username. Script ${_me} can not be run as root!"
        echo -e "${rmColor}"
        echo "" > ${_OUTPUT_PATH}
        return 1
    elif [ -z ${_OUTPUT_PATH} ]; then
        echo -e "${red}No output path given!${rmColor}"
        return 1
    else
        _detectDevs
        # Return
        if [ -z ${_MICROSD_PATH} ]; then
           echo "Error selecting an SD Card"
           return 1
        else
            # Write to file
            echo "${_MICROSD_PATH}" > ${_OUTPUT_PATH}
            return 0
        fi
    fi

    }

# Just read an enter and do nothing else
function _dummyEnter
{
    local dummyEnter
    read -p "Press Enter to continue..." dummyEnter
}

# Get connected device paths
function _getDevs
{
    echo $( lsblk --nodeps --output NAME --paths | \
    grep --no-ignore-case --invert-match -e "NAME" )
}

# Get connected devices and store them in detected_devs array
function _devsWithoutSD
{
    echo "Detecting devices. Please wait."

    # Sleep so devices list is refreshed in Linux
    sleep 5

    for i in $(_getDevs); do
        detected_devs+=(${i})
    done
}

# Get connected devices and compare them with the ones in detected_devs array.
# If a new one is (are) detected, ask user what to do; otherwise, ask for 
# running again.
function _devsWithSD
{
    # Array with the newly detected devs
    declare -a possibleSD

    echo "Detecting devices. Please wait."

    # Sleep so Linux can read new devices
    sleep 10

    # Get new devices and compare them
    for i in $(_getDevs); do
        # Compare each new device with those already listed
        for j in ${detected_devs[@]}; do
            if [ ${i} = ${j} ]; then
                # Device was already detected.
                break

            elif [ ${j} = ${detected_devs[${#detected_devs[@]}-1]} ]; then
                # Device was not listed. Add it to posible micro SD devices
                possibleSD+=(${i})
            fi
        done
    done

    # Perform action according to the ammount of detected devices
    if [ ${#possibleSD[@]} -lt 1 ]; then
        # No new devices
        echo -e "${red}${bold}No new devices were detected.${rmColor} "
        echo "Try waiting a few extra seconds before inserting the "\
            "Micro SD Card."
        # Run again
        read -p "Press Enter to try again." \
            dummyEnter
        _detectDevs    

    elif [ ${#possibleSD[@]} -eq 1 ]; then
        # Exactly one new device
        devSize=$(_devsGetSize ${possibleSD[0]})

        echo -ne "${green}Device ${bold}${possibleSD[0]}${rmBold} with size " 
        echo -e "${bold}${devSize}${rmBold} was detected.${rmColor}"

        # Prompt user
        read -p "Is this correct? [y/N] " ANS
        # Select the new one or run again
        if [ "${ANS,,}" = "yes" ] || [ "${ANS,,}" = "y" ]; then
            _MICROSD_PATH=${possibleSD[0]}
        else
            echo "Running again."
            _detectDevs
        fi

    else
        # Multiple new devices
        index=1

        echo -e "${lyellow}${bold}More than one new devices were detected.${rmColor}"
        echo ""

        # Detected devices table
        printf "%-10s %-15s %-10s\n" "NUMBER" "NAME" "SIZE"
        for i in ${possibleSD[@]}; do
            devSize=$(_devsGetSize ${i})
            printf "%-10d %-15s %-10s\n" ${index} ${i} ${devSize}
            let index++
        done

        echo ""
        # Prompt user
        read -p "Enter the desired device number or press enter to run again (recommended): " ANS

        # Run again or select one
        if [ -z ${ANS} ] || [ ${ANS} -ge $((${#possibleSD[@]}+1)) ] || \
            [ ${ANS} -lt 1 ]; then
            echo "Running again."
            _detectDevs
        else
            devSize=$(_devsGetSize ${i})
            _MICROSD_PATH=${possibleSD[${ANS}-1]}

            echo -ne "${green}Device ${bold}${_MICROSD_PATH}${rmBold} with " 
            echo -e "size ${bold}${devSize}${rmBold} selected.${rmColor}"
        fi
    fi
}

# Get size of a passed device. 
# Takes one argument, a string with the full device path (i.e. "/dev/sda")
# Returns device size
function _devsGetSize
{
    if [ -z $1 ]; then
        echo "Empty device path."
    else
        echo $(lsblk --nodeps --output SIZE --paths ${1} | \
            grep --no-ignore-case --invert-match -e "SIZE")
    fi
}

# Main function of the script
function _detectDevs
{
    # Clear array in case its called from another function
    detected_devs=()

    # Detect devices
    echo ""
    echo -en "${lcyan}Remove any inserted Micro SD Card or USB Micro SD Card "
    echo -e "Reader${rmColor}"
    _dummyEnter
    _devsWithoutSD

    # Detect newly inserted devices
    echo ""
    echo -e "${lcyan}Insert the Micro SD Card${rmColor}"
    _dummyEnter
    _devsWithSD
}

# Run script
getSDCardPath
