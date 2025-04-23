#!/bin/sh
echo "             _____       __"
echo "            / ___/____ _/ /____  ___________ _"
echo "            \__ \/ __ \` //_/ / / / ___/ __ \`/ "
echo "           ___/ / /_/ / ,< / /_/ / /  / /_/ /"
echo "          /____/\__,_/_/|_|\__,_/_/   \__,_/ "
echo "  "
echo "     Welcome to Sakura module builder script!"
echo "  "
echo "     Building process will only take a few seconds or so..."
echo "  "

# Check if zip is available
if command -v zip >/dev/null 2>&1; then
    for file in common/functions.sh common/install.sh common/service.sh \
    META-INF/com/google/android/update-binary META-INF/com/google/android/updater-script \
    customize.sh module.prop uninstall.sh
    do
        dos2unix "$file" || {
            echo " - Error: Can't convert the file from DoS format to Unix format"
            sleep 3
            exit 1
        }
    done
    if ! zip sakura_git_build.zip common META-INF customize.sh module.prop uninstall.sh; then   
        echo " - Error: Failed to create the zip file."
        exit 1
    fi
else
    echo -e "[\e[0;35m$(date +%d-%m-%Y) \e[0;37m- \e[0;32m$(date +%H:%M%p)] [:\e[0;36mABORT\e[0;37m:] - \e[0;31mZip binary wasn't found. Please install it or pack it manually.\e[0;37m"
    sleep 3
    exit 1
fi
echo -e "[\e[0;35m$(date +%d-%m-%Y) \e[0;37m- \e[0;32m$(date +%H:%M%p)\e[0;37m] / [:\e[0;36mMESSAGE\e[0;37m:] / [:\e[0;32mJOB\e[0;37m:] -\e[0;33m The zipfile was packed..\e[0;37m"