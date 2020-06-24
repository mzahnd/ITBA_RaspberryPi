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


# Source this file to be able to run other scripts within yours. You must have
# an USERNAME variable with the user that will run the desired script
# 
# source runScript.sh
# USERNAME=johndoe
#
# And call the function! :)

# Get name and path of a given file
if [ -z ${_script_getFilePathName} ]; then
    source getFilePathName.sh 2> /dev/null
    if [ $? -ne 0 ]; then
        source ../common/getFilePathName.sh
    fi
fi

# Avoid sourcing this script twice
_script_runScript=1

# Run a given script with the passed arguments as a normal user
# Arguments:
# Script path
# Number of arguments to pass to the script
# ... Arguments for the script
#
# Example:
# runScript ~/myfolder/myscript.sh 3 "firstarg" 2 "thirdone"
function runScript()
{
    local scriptPath=$(getFilePath ${1})
    local scriptName=$(getFileName ${1})
    local returnValue=-1

    declare -a _script2RunArgs

    if [ ${2} -gt 0 ]; then
        local counter=${2}
        until [ ${counter} -eq 0 ]; do
            counter=$((--counter))
            shift
            if [ "${2}" = "" ]; then
                _script2RunArgs+=("")
            else
                _script2RunArgs+=(${2})
            fi
        done
    fi

    pushd ${scriptPath} &> /dev/null
    
    # DBG
    #echo "script2run args: ${_script2RunArgs[@]}"

    chmod +x ${scriptName}

    sudo -u ${USERNAME} /bin/bash ${scriptName} "${_script2RunArgs[@]}"
    returnValue=$?

    popd &> /dev/null

    return ${returnValue}
}

