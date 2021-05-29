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
#   local imgpathFile=/tmp/imgpath.tmp
#   # Create it and give it rw permission
#   touch ${imgpathFile}
#   chmod 777 ${imgpathFile}
#   # Call this script as non root
#   sudo -u ${USERNAME} /bin/bash ./getImage.sh ${USERNAME} ${imgpathFile}
#   # Read file and remove it. Stores the path in IMG_PATH variable
#   read -r IMG_PATH < ${imgpathFile}
#   rm ${imgpathFile}
#
#
# Make sure you get a valid username for the corresponding variable. There
# will be downloaded the needed files in case the user does not have a recent
# image ready to burn.
# 

# Non root user where files can be downloaded if needed
_USERNAME=${1}

# Path where IMA_PATH final path must be written
_OUTPUT_PATH=${2}

_HIDE_NONE_OPTION=${3}

# IMG file path (private to this script)
_IMG_PATH=""
# File that could be an either an img or zip with the img
_FILE_PATH=""

# Official Raspbian web page (with the SHA-256 published)
_HTML_RASPBIAN="https://www.raspberrypi.org/downloads/raspbian/"
# Official Raspbian images
_IMAGES_RASPBIAN_LITE="https://downloads.raspberrypi.org/raspbian_lite/images/"
# Path where the zip file will be downloaded if needed
_DOWNLOADED_RASPBIAN_PATH=/home/${_USERNAME}/.cache/raspberrypi
# Path to downloaded img file
_DOWNLOADED_RASPBIAN_IMG=
# Path to downloaded zip file
_DOWNLOADED_RASPBIAN_ZIP=

# Script filename
_me=$(basename $0)

# Colors
if [ -z ${_script_colors} ]; then
    source colors.sh
fi

# This is the only function that should be called from another script.
# Returns a variable called 'IMG_PATH' with a string containing the path to
# the desired img file.
#
# Call this function at the bottom of this script for debugging purposes.
function getImage
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
        _askInput
        echo "${_IMG_PATH}" > ${_OUTPUT_PATH}
        return 0
    fi
}

# Ask user what to do.
# Options are: 
# User has an img or zip file; 
# User has already used this script and wants to retrieve the downloaded file
# User does not have anything, so an image will be downloaded
function _askInput
{
    local validAns=0

    until [ ${validAns} -eq 1 ]; do
        echo -e "${lcyan}Do you have...?${rmColor}"
        echo -en "${bold}1.${rmBold} An '.img' file with an image ready to "
        echo     "burn in my Micro SD Card."
        echo -en "${bold}2.${rmBold} A '.zip' file with an image ready to "
        echo     "burn in my Micro SD Card."
        echo -en "${bold}3.${rmBold} An image previously downloaded by this "
        echo -e "script. But I don't remember where is it."
        if [ ${_HIDE_NONE_OPTION} -ne 1 ]; then
            echo -e "${bold}4.${rmBold} None of the above."
        fi

        if [ ${_HIDE_NONE_OPTION} -eq 1 ]; then
            read -p "Please enter the desired option [1, 2 or 3] " ASK
        else
            read -p "Please enter the desired option [1, 2, 3 or 4] " ASK
        fi
    
        case ${ASK} in
            1)
                # Img file
                local askReturn=1

                echo ""
                _askFilePath "img"
                askReturn=$?
                echo ""

                # Only a 0 return exits the main loop (validAns=1)
                if [ ${askReturn} -eq 0 ]; then
                    validAns=1
                    _IMG_PATH=${_FILE_PATH}
                else
                    validAns=0
                fi
                ;;
            2)
                # Zip file
                local askReturn=1

                echo ""
                _askFilePath "zip"
                askReturn=$?
                echo ""

                # Only a 0 return exits the main loop (validAns=1)
                if [ ${askReturn} -eq 0 ]; then
                    validAns=1
                    _unzipIMG ${_FILE_PATH}
                else
                    validAns=0
                fi
                ;;
            3)
                # Image downloaded by this script
                filesInPath=()
                echo -e "${blue}Checking possible image paths...${rmColor}"

                # Loop in the downloads path seaching for a .img or .zip file
                for i in $(ls -A ${_DOWNLOADED_RASPBIAN_PATH} 2> /dev/null | \
                            grep -Ei "^[_:\.A-Za-z0-9\-]+.(img|zip)$")
                do
                    filesInPath+=(${_DOWNLOADED_RASPBIAN_PATH}/${i})
                done

                # An .img or .zip file was found
                if [ ${#filesInPath[@]} -ne 0 ]; then
                    _imagePrevDownlaoded ${#filesInPath[@]} ${filesInPath[@]}

                    if [ $? -eq 0 ]; then
                        # Exit main loop
                        validAns=1
                    else
                        # Keep in loop
                        validAns=0
                    fi

                # No .img or .zip files found
                else
                    echo -ne "${red}Unable to find an image downloaded using "
                    echo -e "this script.${rmColor}"

                    # Keep in loop
                    validAns=0
                fi
                ;;
            4)
                # Download file
                echo -en "${blue}"
                echo -en "A zip file containing the lastest release will be "
                echo -en "downloaded from the oficial Raspberry Pi website."
                echo -e "${rmColor}"
                _getImageFromWeb
    
                # After getting it, unzip it
                if [ ${_FILE_PATH} != "" ]; then
                    _unzipIMG ${_FILE_PATH}
                fi
                ;;
            *)
                # Invalid option
                echo -e "${red}Invalid option. Please try again.${rmColor}"
                echo ""
                validAns=0
                ;;
        esac
    done
}

# User says it has an img or zip file. Ask the path of it.
# Writes file path in _FILE_PATH variable if its ok or leaves it blank 
# otherwise.
# Arguments:
# 1.- File extension. Either "zip" or "img" strings.
function _askFilePath
{
    # Desired file extension
    local fExtension="${1}"
    
    # File exists (checked later)
    local fileExists=-1

    # File extension (checked later)
    local fExtension_File=""
    
    echo -en "${lcyan}Please enter the full path of the '.${fExtension}' " 
    echo -e "file (Press enter to go back): ${rmColor}" 
    read -p "" ASKPATH

    if [ -z ${ASKPATH} ]; then
        _FILE_PATH=""
        return 2
    fi
    
    _checkFile ${ASKPATH}
    fileExists=$?

    fExtension_File=$(_getFileType ${ASKPATH})
        
    if [[ ${fileExists} -eq 0 && ${fExtension_File} = ${fExtension} ]]; then
        echo -e "${lgreen}File seems OK.${rmColor}"
        _FILE_PATH="${ASKPATH}"
        return 0

    elif [ ${fileExists} -eq 0 ]; then
        echo -ne "${red}The given file does not have '${bold}.${fExtension}"
        echo -en "${rmBold}' extension. Are you sure you selected the correct "
        echo -e "options?"
        echo -e "Please, try again.${rmColor}"
        _FILE_PATH=""
        return 2

    else
        echo -ne "${red}File not found. "
        echo -e "Please, try again.${rmColor}"
        _FILE_PATH=""
        return 1
    fi
}

# Check if a file exists, its size is not zero and is readable.
# Returns 0 if success, 1 otherwise.
# Arguments:
# 1.- Full path to file "/path/to/myfile"
function _checkFile
{
    if [ -f ${1} -a -r ${1} -a -s ${1} ]; then
        return 0
    else
        return 1
    fi
}

# Echoes a string with a the file extension (without the . at the beggining).
# If the file has no extension, echoes "(none)".
# Example: 
# Given "/home/niceUsername/myfile.ext", it will return "ext".
# Given "/home/niceUsername/filewithoutextension", it will return "(none)".
# Arguments:
# 1.- Full path to file "/path/to/myfile"
function _getFileType
{
    # Get files with a file extension with only letters in it
    local filetype=$(echo "${1}" | \
        grep -iE '\.[^\d/][A-Za-z]+$' | \
        awk 'BEGIN{FS="."} {print $NF}')

    if [ -z ${filetype} ]; then
        echo "(none)"
    else
        echo "${filetype}"
    fi
}

# Unzip a file and look for inflated .img files after that.
# This function sets _IMG_PATH variable when an img file is found.
# Arguments:
# 1.- Full path to zip file "/path/to/myfile.zip"
function _unzipIMG
{
    # Full file path (/path/to/file/filename)
    local fileFullPath=${1}
    # File name (filename)
    local fileName=$(_getFileName ${fileFullPath})
    # File path (/path/to/file/)
    local filePath=$(_getFilePath ${fileFullPath})
    # File extension. Used to check if a zip was given
    local fileType_org=$(_getFileType ${fileFullPath})

    # Return value
    local retVal=1

    # Just in case a non zip file is passed
    if [ ${fileType_org} != "zip" ]; then
        echo -e "${red}File is not a zip.${rmColor}"
        return 1
    fi

    # Unzip file
    pushd ${filePath} &> /dev/null
    unzip ${fileName}

    # Check if an .img file was inflated and store it in an array
    # This way, if there is more than one the user can pick one later
    declare -a _zip_images
    _zip_images=()
    for i in $(ls -A | grep -E "^[_:\.A-Za-z0-9\-]+.img$"); do
        _zip_images+=(${i})
    done

    if [ ${#_zip_images[@]} -ne 0 ]; then
        echo -e "${blue}Possible image found inside zip file.${rmColor}"

        # Select an .img file from the array
        _selectFile_return=""
        _selectFile ${#_zip_images[@]} ${_zip_images[@]}
            
        # Check for errors
        if [ "${_selectFile_return}" = "" ]; then
            echo "There was an error while selecting an img file."
            retVal=1
        else
            # Assign selected img file to _IMG_PATH variable
            echo -e "${green}Image seems fine.${rmColor}"
            _IMG_PATH=${filePath}${_selectFile_return}
            retVal=0
        fi

    else
        echo -e "${red}No .img file was found in ${filePath}${rmColor}"
        retVal=1
    fi

    popd &> /dev/null
    return ${retVal}
}

# Echoes a file name given its path
# Arguments:
# 1.- Full path to file "/path/to/myfile"
function _getFileName
{
    local fileName=$(echo ${1} | awk -F '/' '{print $NF}')
    echo "${fileName}"
}

# Echoes the path of a file. Like pwd
# Arguments:
# 1.- Full path to file "/path/to/myfile"
function _getFilePath
{
    local filePath=$(echo ${1} | awk -F "$(_getFileName ${1})" '{print $1}')
    echo "${filePath}"
}

# Given an array with file name, lets the user pick one in case that the array
# has more than one element. If only one file is in the array, automatically
# picks it. If none, prints an error.
#
# Writes variable _selectFile_return with the chosen file.
# Arguments:
# 1.- Number of elements in the array
# 2 (and following).- Names of files that should be picked. One of this will
#       be returned, so it does not matter if it's a full path to the file or
#       just its name, as long as you keep in mind that the string will be
#       returned as given.
#
# Example:
# function _willCallSelectFile
# {
#       # Array with three strings
#       array=("firstOption" "secondOption" "/thirdOption/with/path/2file.ext")
#
#       # Here will be returned the selected option
#       _selectFile_return=""
#
#       # Passing the number of elements in the array first, and then the
#       # array itself
#       _selectFile ${#array[@]} ${array[@]}
#       
#       # _selectFile will print the following to the user:
#
#       # The folowwing files where found in the same directory.
#       # Please select the one you'd like to use: 
#       #
#       # #        NAME                                          SIZE      
#       # 1        firstOption                                   8G      
#       # 2        secondOption                                  434M      
#       # 3        /thirdOption/with/path/2file.ext              1,8G 
#       #
#       # Enter the desired file number: 
#
#       # Supposing the user entered number 2, _selectFile_return will be
#       # _selectFile_return="secondOption"
# }
function _selectFile
{
    # String that will be returned with the chosen file
    _selectFile_return=""

    # Array with possible files (in case there are more than one)
    declare -a _selectFile_possible

    let counter=${1}
    until [ ${counter} -eq 0 ]; do
        let counter--
        # Magic trick to move the arguments position
        shift
        _selectFile_possible+=(${1})
    done

    echo ""

    # If only one file is found, pick it. Otherwise, let the user choose one
    case ${#_selectFile_possible[@]} in
        0)
            # Error. Bad argument passed to function or code bug
            echo -e "${red}There was an error selecting the file.${rmColor}"
            _selectFile_return=""
            ;;
        1)
            # Only one value in the array
            _selectFile_return="${_selectFile_possible[0]}"
            ;;
        *)
            # Multiple files in the array
            echo -e "${lcyna}The folowwing files where found."
            echo -e "Please select the one you'd like to use: ${rmColor}"
            echo ""

            # Table header
            printf "%-8s %-45s %-10s\n" "#" "NAME" "SIZE"

            # Table content
            let index=0
            for i in ${_selectFile_possible[@]}; do
                local fileSize=$(_getFileSize ${i})
                let index++

                printf "%-8d %-45s %-10s\n" ${index} ${i} ${fileSize}
            done

            # Loop until a valid index number is given
            local validAnswer=0
            while [ ${validAnswer} -eq 0 ]; do 
                echo ""
                read -p "Enter the desired file number: " ANS

                # Check valid answer
                if [ -z ${ANS} ] || [ ${ANS} -gt ${index} ] \
                    || [ ${ANS} -lt 1 ]; then
                    # Invalid input
                    echo -e "${red}Invalid option. Please try again${rmColor}"
                else
                    # Return chosen file name
                    validAnswer=1
                    _selectFile_return="${_selectFile_possible[${ANS}-1]}"
                fi
            done
            ;;
    esac
}

# Echoes a string with file size in human readable format
# Arguments:
# 1.- Full path to file "/path/to/myfile"
function _getFileSize
{
    local file=${1}
    echo "$(du -h ${file} | awk '{print $1}')"
}

# Takes an array with possible files in the same directory and lets the user
# pick which one should be used.
# All strings with paths to files MUST have .zip and/or .img extension and
# be in the same directory.
#
# This function sets _IMG_PATH variable when an img file is found.
#
# Arguments:
# 1.- Number of elements in the array
# 2 (and following).- Full path to files that should be picked. Remember, with
#               .img or .zip extension and all in the same directory
# Example:
#            # Array with files 
#            filesInPath=()
#            # Get only files with zip or img extension in a giver directory
#            for i in $(ls -A /dir/with/files/ 2> /dev/null | \
#                            grep -Ei "^[_:\.A-Za-z0-9\-]+.(img|zip)$"); do
#               # Put files in the array
#               filesInPath+=(/dir/with/files/${i})
#            done
#
#           # Call function passing the number of elements and the whole array
#            _imagePrevDownlaoded ${#filesInPath[@]} ${filesInPath[@]}
function _imagePrevDownlaoded
{
    # "(none)" by default, it will be replaced by "zip" or "img" if everything
    # is ok
    local fileType="(none)"

    # Return value at the end of the funcion
    local retValue=1

    # List of files from where one will be chosen
    _files2use=()
    let counter=${1}

    # Bug catcher
    if [ -z "${counter}" ] || [ ${counter} -eq 0 ] || [ ${2} = "" ]; then
        echo -e "${red}Zero paths passed. Aborting${rmColor}"
        return 1
    fi

    # Get the path of the given files. As they are supposed to be all in the,
    # same place the first one is used to get the path
    local filePath=$(_getFilePath ${2})

    # Enter the directory. We do not want the user to see the full path of
    # any file later, as this can confuse her/him
    pushd ${filePath} &> /dev/null

    # Put each file name in an array (needed to call _selectFile a few lines
    # below)
    until [ ${counter} -eq 0 ]; do
        let counter--
        shift
        _files2use+=("$(_getFileName ${1})")
    done

    # Bug catcher
    if [ ${#_files2use[@]} -eq 0 ]; then
        echo -e "${red}Bad function call. _imagePrevDownloaded.${rmColor}"
        popd &> /dev/null
        return 1
    fi

    # Select a file from the array
    _selectFile_return=""
    _selectFile ${#_files2use[@]} ${_files2use[@]}

    # Get the extension of the selected file
    if [ ! -z ${_selectFile_return} ]; then
        fileType=$(_getFileType ${_selectFile_return})
    else
        # Clear fileType so the following switch aborts
        fileType="(none)"
    fi

    case ${fileType} in
        "zip")
            # Inflate the image if it's a zip file
            # This function sets _IMG_PATH if successfull. No need to set 
            # it again
            _unzipIMG ${filePath}${_selectFile_return}
            retVal=$?
            ;;
        "img")
            # Nice, we found an img file
            _IMG_PATH=${filePath}${_selectFile_return}
            retVal=0
            ;;
        *)
            echo "${red}File type error in _imagePrevDownloaded.${rmColor}"
            popd &> /dev/null
            retVal=1
        ;;
    esac

    # Return to the previous dir
    popd &> /dev/null
    return ${retVal}
}

# Wrapper to download a zip file from _HTML_RASPBIAN and verify if it has a 
# valid SHA256.
# Writes the path to the zip in _FILE_PATH variable.
function _getImageFromWeb
{
    _FILE_PATH=""
    echo -en "${blue}Prepearing to download the image from${rmColor} "
    echo -e "${_HTML_RASPBIAN}"

    # Creates directory if it does not exists
    mkdir -p ${_DOWNLOADED_RASPBIAN_PATH} &> /dev/null

    # Get all SHA256 sums published in the official site
    local possibleSHA=$(_webGetSHA)

    # Download zip file with the image
    _webGetIMG

    # In case of error, try again
    if [ $? -ne 0 ]; then
        _askInput
    fi

    # Compare file SHA with the gotten ones
    let validSHA=0
    local fileSHA=$(sha256sum ${_DOWNLOADED_RASPBIAN_ZIP} | \
        awk '{print $1}' 2> /dev/null)
    for i in ${possibleSHA}; do
        if [ "${fileSHA}"  = "${i}" ]; then
            let validSHA++
        fi
    done

    # No valid SHA-256
    # Valid SHA-256
    # More than one valid SHA-256 (just in case there is a bug in this code or
    #                              the Raspberry Pi site has changed somehow)
    case ${validSHA} in
        0)
            echo -ne "${red}No valid SHA-256 were found when comparing the "
            echo -ne "downloaded ZIP file with the ones got from "
            echo -e "${_HTML_RASPBIAN}${rmColor}"
            echo -e "${lyellow}The downloaded file SHA-256 is: ${rmColor}"
            echo -e "${fileSHA}"
            echo -en "${lyellow}This was compared with the following SHA-256: "
            echo -e "${rmColor}"
            for i in ${possibleSHA}; do
                echo ${i}
            done
            echo ""
            echo "The downloaded file is:"
            echo "${_DOWNLOADED_RASPBIAN_ZIP}"
            echo ""
            echo -n "Do you still want to proceed? This could be dangerous. "
            echo "[y/N] "
            read ASKSHA
            ;;
        1)
            echo -en "${lgreen}The downloaded ZIP file matches one SHA-256 "
            echo -e "from ${_HTML_RASPBIAN}${rmColor}"
            ASKSHA="y"
            ;;
        *)
            echo -ne "${lyellow}The downloaded ZIP file matches more than one "
            echo -e "SHA-256 from ${_HTML_RASPBIAN}"
            echo -ne "This could be a software issue or there is something "
            echo -ne "wrong with the website. It's recommended to manually "
            echo -e "check before going on.${rmColor}"
            echo ""
            echo "The downloaded file is:"
            echo "${_DOWNLOADED_RASPBIAN_ZIP}"
            echo ""
            read -p "Do you want to continue? [y/N] " ASKSHA
            ;;
    esac

    if [ ${ASKSHA,,} = "y" ] || [ ${ASKSHA,,}  = "yes" ]; then
        _FILE_PATH=${_DOWNLOADED_RASPBIAN_ZIP}
    fi
}

# Get all SHA256 sums published in the official site
# Downloads _HTML_RASPBIAN html and gets all the SHA-256 published there.
# Why this one and not the .zip.sha file stored alongside the zip file? 
# ¯\_(ツ)_/¯ There is not a valid reason.
function _webGetSHA
{
    local html_path=/tmp/raspbian.html
    local dummyFilePath=/tmp/dummyFile
    local dummySHA=""
    local sha256sums=""

    # Download the webpage with the SHA256 published
    curl --silent --proto =https "${_HTML_RASPBIAN}" > ${html_path}

    # Create a dummy file and get a dummy SHA256
    touch ${dummyFilePath}
    dummySHA=$(sha256sum ${dummyFilePath} | awk '{print $1}')

    # Grep line with a "SHA-256:"
    sumsgrep=$(grep "SHA-256:" < ${html_path} > ${dummyFilePath})

    # Find awk column with the hash comparing sizes with the dummy hash
    # The last condition is meant to avoid an infinite loop bug
    let counter=0
    until [[ ${#sha256sums} -eq ${#dummySHA} || counter -eq 200 ]]; do
        let counter++
        # Get only the first match of an SHA256 hash
        sha256sums=$(awk \
            -v pos=$counter \
            -F '<[/\"0-9A-Za-z \\[\\]=\\-_:\\.]+>' \
            '{print $pos;exit}' < ${dummyFilePath})
    done
    
    # Using the column found in the previous step, get every SHA256 hashes
    sha256sums=$(awk \
        -v pos=$counter \
        -F '<[/\"0-9A-Za-z \\[\\]=\\-_:\\.]+>' \
        '{print $pos}' < ${dummyFilePath})

    # Delete files
    rm ${html_path}
    rm ${dummyFilePath}

    # Return sums
    echo ${sha256sums}
}

# Downloads the latest zip from _IMAGES_RASPBIAN_LITE, stores it in 
# _DOWNLOADED_RASPBIAN_PATH and writes  _DOWNLOADED_RASPBIAN_ZIP with the full
# path if everything runs fine
function _webGetIMG
{
    local html_path=/tmp/raspimgs
    local dummyFilePath=/tmp/dummyFile
    local stringWithVer=""
    # Zip File to download name
    local zipFile=""

    echo -ne "${blue}Downloading image in${rmColor} "
    echo -e "${_DOWNLOADED_RASPBIAN_PATH}"
    pushd ${_DOWNLOADED_RASPBIAN_PATH} &> /dev/null

    # Download _IMAGES_RASPBIAN_LITE html to get the latest version
    curl --silent --proto =https "${_IMAGES_RASPBIAN_LITE}" > ${html_path}

    # Get the last uploaded folder related with raspbian_lite
    tail -n 4 ${html_path} | grep "raspbian_lite" > ${dummyFilePath}
   
    # Get the "raspbian_lite" string with the last uploaded date
    # The last condition in the loop is meant to avoid an inifite loop
    let counter=0
    until [[ "$(echo ${stringWithVer} | \
        awk 'BEGIN{FS="-"} {print $1}')" = \
        "raspbian_lite" || counter -eq 200 ]]
        do
            let counter++
            
            # The first awk cuts the text and searches for a "raspbian_lite"
            # string. The second one removes a '/' that's always at the end
            # of the string.
            stringWithVer=$(awk \
                -v pos=$counter \
                -F '<[/\"0-9A-Za-z \\[\\]=\\-_:\\.]+>' \
                '{print $pos}' < ${dummyFilePath} | \
                awk 'BEGIN{FS="/"} {print $1}')
    done

    # Bug catcher
    if [ ${counter} -ge 199 ]; then
        echo -e "${red}There was an error downloading the zip file."
        echo -e "Newest version could not be found.${rmColor}"
    fi

    # Up to now, the _IMAGES_RASPBIAN_LITE html has been downloaded and readed
    # in order to get the latest versions' name. Now, having that, the script
    # will enter _IMAGES_RASPBIAN_LITE/gettedVersion/ and check for the zip 
    # file per se.

    # Download the new html to get the zip file name
    curl --silent --proto =https \
        "${_IMAGES_RASPBIAN_LITE}/${stringWithVer}/" | \
        grep -Ei '.+\.zip[^\.]' > ${html_path}

    # Get the zip file!
    # The last condition in the loop is meant to avoid an inifite loop
    let counter=0
    while [[ -z "$(echo ${zipFile} | \
        grep ".zip")" || counter -eq 200 ]]
        do
            let counter++

            zipFile=$(awk \
               -v pos=$counter \
               -F '<[/\"0-9A-Za-z \\[\\]=\\-_:\\.]+>' \
               '{print $pos}' < ${html_path})
    done

    # Bug catcher
    if [ ${counter} -ge 199 ]; then
        echo -e "${red}There was an error downloading the zip file."
        echo -e "ZIP file could not be found.${rmColor}"
    fi


    # Delete temporal files
    rm ${html_path}
    rm ${dummyFilePath}

    # Finally, download the file
    curl \
        --progress-bar \
        --proto =https \
        --remote-name \
        "${_IMAGES_RASPBIAN_LITE}/${stringWithVer}/${zipFile}"
    #echo -e "${red}==== Fake download ====${rmColor}"
    local curlOut=$?
    
    _checkFile "${_DOWNLOADED_RASPBIAN_PATH}/${zipFile}"
    local validDownload=$?

    if [[ ${curlOut} -eq 0 ]] && [[ ${validDownload} -eq 0 ]]; then
        popd &> /dev/null
        echo -e "${green}File downloaded without errors.${rmColor}"
        _DOWNLOADED_RASPBIAN_ZIP=${_DOWNLOADED_RASPBIAN_PATH}/${zipFile}
        return 0
    else
        popd &> /dev/null
        echo -en "${red}There was an error while downloading the file. "
        echo -e "Please try again.${rmColor}"
        _DOWNLOADED_RASPBIAN_ZIP=""
        return 1
    fi
}

# For debbuging this file. Remember to uncomment "Fake download" string
getImage
