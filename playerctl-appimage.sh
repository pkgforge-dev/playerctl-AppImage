#!/bin/sh

APP=playerctl
APPDIR="$APP".AppDir
REPO="https://github.com/altdesktop/playerctl.git"

# CREATE DIRECTORIES
if [ -z "$APP" ]; then exit 1; fi
mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1

# DOWNLOAD AND BUILD PLAYERCTL STATICALLY
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
CFLAGS='-static -O3' 
LDFLAGS="-static"

git clone --recursive "$REPO" && cd playerctl \
&& meson setup build -Dprefix="$CURRENTDIR" -Ddefault_library=static -Dgtk-doc=false -Dintrospection=false \
&& ninja -C build && ninja -C build install && cd .. && rm -rf ./playerctl ./include \
&& sed -i 's#Exec=.*#Exec=playerctl daemon#g' ./share/dbus-1/services/org.mpris.MediaPlayer2.playerctld.service || exit 1

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
DATADIR="${XDG_DATA_HOME:-$HOME/.local/share}"

if [ "$1" = "--install-daemon" ]; then
	mkdir -p "$DATADIR"/dbus-1/services \
	&& cp "$CURRENTDIR"/share/dbus-1/services/* "$DATADIR"/dbus-1/services || exit 1
	echo "Dbus service installed at $DATADIR/dbus-1/services"
elif [ "$1" = "daemon" ]; then
	if ! ls "$DATADIR"/dbus-1/services/*playerctld* 1>/dev/null; then
		echo "You need to run --install-daemon to install the dbus service, bailing out"
		exit 1
	fi
	"$CURRENTDIR"/bin/playerctld
elif [ -z "$@" ]; then
	"$CURRENTDIR"/bin/playerctl
	echo "AppImage commands:"
	echo " --install-daemon	Installs the dbus service in $DATADIR"
	echo " daemon			Starts playerctld daemon"
else
	"$CURRENTDIR"/bin/playerctl "$@"
fi
EOF
chmod a+x ./AppRun

APPVERSION=$(./AppRun --version | awk '{print $1}')

# Desktop
cat >> ./"$APP.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=playerctl
Icon=playerctl
Exec=playerctl
Categories=System
Hidden=true
EOF

# Icon
touch ./"$APP".png && ln -s ./"$APP".png ./.DirIcon # Does playerctl have an official icon?

# MAKE APPIMAGE
cd ..
APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/"/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')
wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod a+x ./appimagetool

# Do the thing!
ARCH=x86_64 VERSION="$APPVERSION" ./appimagetool -s ./"$APPDIR"
ls ./*.AppImage || { echo "appimagetool failed to make the appimage"; exit 1; }
if [ -z "$APP" ]; then exit 1; fi # Being extra safe lol
mv ./*.AppImage .. && cd .. && rm -rf ./"$APP"
echo "All Done!"
