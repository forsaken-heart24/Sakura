function grep_prop() {
	local variable_name=$1
	local prop_file=$2
	local args="$#"
    [ ! "$args" -eq "2" ] && return 1
	grep "$variable_name" $prop_file | cut -d '=' -f 2 | sed 's/"//g'
}

function is_boot_completed() {
    [ "$(getprop sys.boot_completed)" == "1" ] && return 0
	return 1
}

function is_bootanimation_exited() {
    [ "$(getprop service.bootanim.exit)" == "1" ] && return 0
	return 1
}

function maybe_set_prop() {
    local prop="$1"
    local contains="$2"
    local value="$3"
    [[ "$(getprop "$prop")" == *"$contains"* ]] && resetprop "$prop" "$value"
}

function string_case() {
    local smile="$(echo $1 | tr '[:upper:]' '[:lower:]')"
    local string="$2"
    case $smile in
        --lower*|-l*)
            echo "$string" | tr '[:upper:]' '[:lower:]'
        ;;
        --upper*|-u*)
            echo "$string" | tr '[:lower:]' '[:upper:]'
        ;;
        *)
            echo "$string"
        ;;
    esac
}

function maybe_nuke_prop() {
    local variable="$1"
    [[ -n "$(command -v resetprop)" && -n "$(resetprop $variable)" ]] && resetprop -d $variable
}

function write() {
    local file=$1
    local value=$2
    [[ "$#" -ge "2" && -f "$file" ]] && echo "$value" > $file
}

contains_reset_prop() {
    local prop="$1"
    local propval="$2"
    local propswitchval="$3"
    # bomb.
    [ "$(resetprop ${prop})" == "${propval}" ] && resetprop $prop $propswitchval
}

########################################### effectless services #####################################
{
    for U in $(ls /data/user); do
        for C in "auth.managed.admin.DeviceAdminReceiver" "mdm.receivers.MdmDeviceAdminReceiver"; do
            pm disable --user $U com.google.android.gms/com.google.android.gms.$C
        done
    done
    GMS0="\"com.google.android.gms\""
    STR1="allow-unthrottled-location package=$GMS0"
    STR2="allow-ignore-location-settings package=$GMS0"
    STR3="allow-in-power-save package=$GMS0"
    STR4="allow-in-data-usage-save package=$GMS0"
    find /data/adb/* -type f -iname "*.xml" -print |
    while IFS= read -r XML; do
        for X in $XML; do
            if grep -qE "$STR1|$STR2|$STR3|$STR4" $X 2>/dev/null; then
                sed -i "/$STR1/d;/$STR2/d;/$STR3/d;/$STR4/d" $X
            fi
        done
    done
    dumpsys deviceidle whitelist -com.google.android.gms
}
########################################### effectless services #####################################

############################################ late_start_services ############################################################
# spoof the device to green state, making it seem like an locked device.
if is_bootanimation_exited; then
    check_reset_prop "ro.boot.vbmeta.device_state" "locked"
    check_reset_prop "ro.boot.verifiedbootstate" "green"
    check_reset_prop "ro.boot.flash.locked" "1"
    check_reset_prop "ro.boot.veritymode" "enforcing"
    check_reset_prop "ro.boot.warranty_bit" "0"
    check_reset_prop "ro.warranty_bit" "0"
    check_reset_prop "ro.debuggable" "0"
    check_reset_prop "ro.secure" "1"
    check_reset_prop "ro.adb.secure" "1"
    check_reset_prop "ro.build.type" "user"
    check_reset_prop "ro.build.tags" "release-keys"
    check_reset_prop "ro.vendor.boot.warranty_bit" "0"
    check_reset_prop "ro.vendor.warranty_bit" "0"
    check_reset_prop "vendor.boot.vbmeta.device_state" "locked"
    check_reset_prop "vendor.boot.verifiedbootstate" "green"
    check_reset_prop "ro.secureboot.lockstate" "locked"
    # Hide that we booted from recovery when magisk is in recovery mode
    contains_reset_prop "ro.bootmode" "recovery" "unknown"
    contains_reset_prop "ro.boot.bootmode" "recovery" "unknown"
    contains_reset_prop "vendor.boot.bootmode" "recovery" "unknown"
    # nuke these mfs if they have any value
    maybe_nuke_prop persist.log.tag.LSPosed
    maybe_nuke_prop persist.log.tag.LSPosed-Bridge
    maybe_nuke_prop ro.build.selinux
    for Disable_Log_Visibility_For_These_Apps in $(pm list packages | cut -d':' -f2); do
        cmd package log-visibility --disable $Disable_Log_Visibility_For_These_Apps
    done
fi
############################################ late_start_services ############################################################

# let's clear the system logs and exit with '0' because we dont want to f-around things lol
logcat -c
cmd notification post --tag "Sakura" --priority 3 --title "Late Start Service" --text "Hello user, sakura improved your device via tweaking stuffs, please provide your feedback at : @lunaromslore24 in telegram, Have a great day :D"
exit 0