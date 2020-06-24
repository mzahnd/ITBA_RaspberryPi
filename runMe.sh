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


# Create a Micro SD Card with a Raspbian Lite image file.

# Enter script path
SCRIPT_DIR="$(dirname ${BASH_SOURCE[0]})"
pushd "${SCRIPT_DIR}" &> /dev/null

# SD Card creator script path
SCRIPT_SDCREATOR_PATH="scripts/creator/sdCreator.sh"

# Image cloner script path
SCRIPT_CLONER_PATH="scripts/cloner/cloner.sh"

# Dependencies for all scripts are here
declare -a REQUIRED=( \
    lsblk du df awk unzip curl tail dd parted losetup tune2fs \
    md5sum sha256sum e2fsck resize2fs )

# Avoid running as root. It must be run as a normal user in order to get an
# username. sdCreator.sh will be run as root.
if [ ${UID} -eq 0 ]; then
    echo -ne "\e[31mPlease do not run this script as root. Root privileges "
    echo -e "will be asked to you by the script.\e[0m"

    exit 1
fi

# Add colors
if [ -z ${_script_colors} ]; then
    source scripts/common/colors.sh
fi

# Run the other scripts
if [ -z ${_script_runScript} ]; then
    pushd scripts/common/ &> /dev/null
    source runScript.sh
    popd &> /dev/null
fi

# Welcome logo
function welcomeMessage()
{
    # https://www.raspberrypi.org/forums/viewtopic.php?t=5494
    echo "$(tput setaf 2)
       .~~.   .~~. 
      '. \ ' ' / .'$(tput setaf 1)
       .~ .~~~..~.
      : .~.'~'.~. :
     ~ (   ) (   ) ~
    ( : '~'.~.'~' : )
     ~ .~ (   ) ~. ~
      (  : '~' :  ) $(tput sgr0)Raspberry Pi$(tput setaf 1)
       '~ .~~~. ~'  $(tput sgr0)Image Manager$(tput setaf 1)
           '~'
    $(tput sgr0)"
}

# Check that the system meets all dependencies
# Function copied from PiShrink script.
function checkDeps()
{
    #echo "Checking deps..."
    for dep in ${REQUIRED[@]}; do
        command -v ${dep} >/dev/null 2>&1
        if (( $? != 0 )); then
            echo -e "${red}Error: ${dep} is not installed.${rmColor}"
            exit -1
        fi      
    done
}

# Ask the user what (s)he would like to do. Create an img or burn/clone a uSD
function askWhat2Do()
{
    # Loop has a valid input. Used for keep looping on invalid answers
    local validInput=0
    # Function return value
    local returnValue=-1
    
    while [ ${validInput} -eq 0 ]; do
        # Clear ASKUSER variable
        local ASKUSER=""

        echo -e "${lcyan}What would you like to do?${rmColor}"
        echo -en "${bold}1.${rmBold} Create a brand new image file in a Micro "
        echo -e "SD Card."
        echo -en "${bold}2.${rmBold} Clone an existing Micro SD Card or use "
        echo -e "an already cloned image in another(s) Micro SD Card(s)."
        echo -n "Please enter the desired option: "

        read ASKUSER

        case ${ASKUSER} in
            1)
                # Create a uSD Card
                validInput=1
                
                createSD
                returnValue=$?
                ;;
    
            2)
                # Clone or burn uSDs
                validInput=1

                cloneImgs
                returnValue=$?
                ;;
    
            *)
                # Invalid input
                echo -e "${red}Invalid option. Please try again.${rmColor}"
                echo ""
                ;;
        esac
    done

    # Return
    return ${returnValue}
}


# Call SDCREATOR script to create an SD Card with Raspbian
function createSD()
{
    # Run the script as root but give it a non root username
    USERNAME=root

    runScript "${SCRIPT_SDCREATOR_PATH}" 2 1 "$(whoami)"
    return $?
}

# Clone one or multiple images
function cloneImgs()
{
    # Run the script as root but give it a non root username
    USERNAME=root

    runScript "${SCRIPT_CLONER_PATH}" 2 1 "$(whoami)"
    return $?
}

# MAIN
checkDeps
welcomeMessage
askWhat2Do

# Exit script path
popd &> /dev/null
exit $?
