# Set variables
[ $API -lt 26 ] && DYNLIB=false
[ -z $DYNLIB ] && DYNLIB=false
[ -z $DEBUG ] && DEBUG=false
INFO=$NVBASE/modules/.$MODID-files
ORIGDIR="$MAGISKTMP/mirror"

# aaaaaaaaaaaaaa
if $DYNLIB; then
	LIBPATCH="\/vendor"
	LIBDIR=/system/vendor
else
	LIBPATCH="\/system"
	LIBDIR=/system
fi

ui_print "             _____       __"
ui_print "            / ___/____ _/ /____  ___________ _"
ui_print "            \__ \/ __ \` //_/ / / / ___/ __ \`/"
ui_print "           ___/ / /_/ / ,< / /_/ / /  / /_/ /"
ui_print "          /____/\__,_/_/|_|\__,_/_/   \__,_/"
ui_print "  "
ui_print "     Welcome to Sakura module installation wizard!"
ui_print "  "
sleep 1.5
ui_print "     Installation process will only take few seconds or so..."
ui_print "  "
sleep 1

# rcm lore.
if ! $BOOTMODE; then
	ui_print "     Only uninstallation is supported in recovery"
	touch $MODPATH/remove
	[ -s $INFO ] && install_script $MODPATH/uninstall.sh || rm -f $INFO $MODPATH/uninstall.sh
	recovery_cleanup
	cleanup
	rm -rf $NVBASE/modules_update/$MODID $TMPDIR 2>/dev/null
	abort "     Uninstallation is finished! Thanks for considering my module :)"
fi

# prevent initializing add-ons if we dont have to.
if [ "$DO_WE_REALLY_NEED_ADDONS" == "true" ]; then
	if [ "$(ls -A $MODPATH/common/addon/*/install.sh 2>/dev/null)" ]; then
		ui_print "     Running Addons...."
		for i in $MODPATH/common/addon/*/install.sh; do
			ui_print "     Running $(echo $i | sed -r "s|$MODPATH/common/addon/(.*)/install.sh|\1|")..."
			. $i
		done
	fi
fi

# make an bool to prevent extracting things if we dont have anything to extract...
if [ "$DO_WE_HAVE_ANYTHING_TO_EXTRACT" == "true" ]; then
	ui_print "     Extracting files..."
	unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
fi

ui_print "     The module setup is finished, thnx for using my module :D"