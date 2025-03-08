function grep_prop() {
	local variable_name=$1
	local prop_file=$2
	local args="$#"
	if [ ! "$args" -eq "2" ]; then
		return 1
	fi
	grep "$variable_name" $prop_file | cut -d '=' -f 2 | sed 's/"//g'
}

function is_boot_completed() {
	if [ "$(getprop sys.boot_completed)" == "1" ]; then
		return 0
	else 
		return 1
	fi
}

function is_bootanimation_exited() {
	if [ "$(getprop service.bootanim.exit)" == "1" ]; then
		return 0
	else 
		return 1
	fi
}

function maybe_set_prop() {
    local prop="$1"
    local contains="$2"
    local value="$3"
    if [[ "$(getprop "$prop")" == *"$contains"* ]]; then
        resetprop "$prop" "$value"
    fi
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
    local variable="$@"
    if [[ ! -z "$(command -v resetprop)" && ! -z "$(resetprop $variable)" ]]; then
        resetprop -d $variable
    fi
}

function write() {
    local file=$1
    local value=$2
    if [ "$#" -ge "2" ]; then
        if [ -f "$file" ]; then
            echo "$value" > $file
        fi
    fi
}

contains_reset_prop() {
    local prop="$1"
    local propval="$2"
    local propswitchval="$3"

    # bomb.
    if [ "$(resetprop ${prop})" == "${propval}" ]; then
        resetprop $prop $propswitchval
    fi
}

########################################### effectless services #####################################

# gms doze crap 
{
    # Disable collective device administrators for all users
    for U in $(ls /data/user); do
        for C in "auth.managed.admin.DeviceAdminReceiver" "mdm.receivers.MdmDeviceAdminReceiver"; do
            pm disable --user $U com.google.android.gms/com.google.android.gms.$C
        done
    done
    # The GMS0 variable holds the Google Mobile Services package name
    GMS0="\"com.google.android.gms\""
    STR1="allow-unthrottled-location package=$GMS0"
    STR2="allow-ignore-location-settings package=$GMS0"
    STR3="allow-in-power-save package=$GMS0"
    STR4="allow-in-data-usage-save package=$GMS0"
    # Find all XML files under /data/adb directory (case-insensitive search for .xml files)
    find /data/adb/* -type f -iname "*.xml" -print |
    while IFS= read -r XML; do
        for X in $XML; do
        # If any of the defined strings (STR1, STR2, STR3, STR4) are found in the file,
        # execute the following block
        if grep -qE "$STR1|$STR2|$STR3|$STR4" $X 2>/dev/null; then
            # Use sed to remove the matched strings from the XML file
            # It deletes lines containing any of STR1, STR2, STR3, or STR4
            sed -i "/$STR1/d;/$STR2/d;/$STR3/d;/$STR4/d" $X
        fi
        done
    done
    # Add GMS to battery optimization
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

############################################ kernel tweaks ##############################################

write /proc/sys/kernel/sched_migration_cost_ns 50000
write /proc/sys/kernel/sched_min_granularity_ns 1000000
write /proc/sys/kernel/sched_wakeup_granularity_ns 1500000
write /proc/sys/kernel/timer_mitigration 0
write /proc/sys/kernel/sched_min_task_util_for_colocation 0
write /proc/sys/kernel/sched_child_runs_first 1
write /proc/sys/kernel/sched_autogroup_enabled 0
write /proc/sys/kernel/perf_cpu_time_max_percent 10
write /proc/sys/kernel/printk_devkmsg off
for queue in /sys/block/*/queue; do
    write "$queue/iostats" 0
    write "$queue/nr_requests" 64
done
write /proc/sys/vm/vfs_cache_pressure 50
write /proc/sys/vm/stat_interval 30
write /proc/sys/vm/compaction_proactiveness 0
write /proc/sys/vm/page-cluster 0
write /sys/kernel/mm/lru_gen/min_ttl_ms 5000

############################################ kernel tweaks ##############################################

# let's clear the system logs and exit with '0' because we dont want to f-around things lol
logcat -c
cmd notification post --tag "Sakura" --priority 3 --title "Late Start Service" --text "Hello user, sakura improved your device via tweaking stuffs, please provide your feedback at : @lunaromslore24 in telegram, Have a great day :D"
exit 0