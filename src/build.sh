#!/bin/sh

function dos2unixconv() {
    local localDoSFile="$1"
    local countedArguments="$#"

    # let's skip if we are not running in a wsl shell - nein nein nein!
    #if ! uname -a | grep microsoft; then
        #return 0
    #fi

    # let's skip this instance if the given file is already an unix file
    if awk '{if (index($0, "\r")) exit 0} END {exit 1}'; then
        echo " - Skipping the conversion of ${localDoSFile}..."
        return 0
    fi

    # Check for argument count
    if [ "$countedArguments" -ne 1 ]; then
        echo " - Can't convert this file. Please provide both a source file and a target directory."
        return 1
    fi

    # Check if dos2unix is available
    if ! command -v dos2unix >/dev/null 2>&1; then
        echo " - Can't find the dos2unix binary to convert this file. Please install it."
        return 1
    fi

    # Perform the conversion
    dos2unix "$localDoSFile" "${localDoSFile}.unix" || {
        echo " - Error: Failed to convert $localDoSFile"
        return 1
    }

    # Remove the original file and move the converted file
    if [ -f "${localDoSFile}.unix" ]; then
        rm -f "$localDoSFile"
        mv "${localDoSFile}.unix" "$localDoSFile" || {
            echo " - Error: Failed to convert this file: $localDoSFile"
            return 1
        }
        return 0
    else
        echo " - Conversion failed. The .unix file doesn't exist."
        return 1
    fi
}


echo "             _____       __"
echo "            / ___/____ _/ /____  ___________ _"
echo "            \__ \/ __ \` //_/ / / / ___/ __ \`/ "
echo "           ___/ / /_/ / ,< / /_/ / /  / /_/ /"
echo "          /____/\__,_/_/|_|\__,_/_/   \__,_/ "
echo "  "
echo "     Welcome to Sakura module builder script!"
echo "  "
sleep 1.5
echo "     Building process will only take a few seconds or so..."
echo "  "
sleep 1

# Check if zip is available
if command -v zip >/dev/null 2>&1; then
    for file in common/functions.sh common/install.sh common/service.sh \
    META-INF/com/google/android/update-binary META-INF/com/google/android/updater-script \
    customize.sh module.prop uninstall.sh
    do
        dos2unixconv "$file" || {
            echo " - Error: Can't convert the file from DoS format to Unix format"
            theShitGotBreaked=true
            break
        }
    done
    [ "${theShitGotBreaked}" == "true" ] || zip sakura_git_build.zip common META-INF customize.sh module.prop uninstall.sh || { echo " - Error: Failed to create the zip file."; exit 1; }
else
    echo -e "[\e[0;35m$(date +%d-%m-%Y) \e[0;37m- \e[0;32m$(date +%H:%M%p)] [:\e[0;36mABORT\e[0;37m:] - \e[0;31mZip binary wasn't found. Please install it or pack it manually.\e[0;37m"
fi
echo -e "[\e[0;35m$(date +%d-%m-%Y) \e[0;37m- \e[0;32m$(date +%H:%M%p)\e[0;37m] / [:\e[0;36mMESSAGE\e[0;37m:] / [:\e[0;32mJOB\e[0;37m:] -\e[0;33m The zipfile was packed..\e[0;37m"
sleep 1