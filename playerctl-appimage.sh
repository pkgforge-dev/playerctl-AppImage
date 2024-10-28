#!/bin/sh

set -u

APP=playerctl
APPDIR="$APP".AppDir
REPO="https://github.com/altdesktop/playerctl.git"
export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
SHARUN="https://bin.ajam.dev/$ARCH/sharun"

# CREATE DIRECTORIES
mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1

# DOWNLOAD AND BUILD PLAYERCTL STATICALLY
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
CFLAGS='-static -O3'
LDFLAGS="-static"

git clone --recursive "$REPO" && cd playerctl \
	&& meson setup build -Dprefix="$CURRENTDIR" -Dgtk-doc=false -Dintrospection=false \
	&& ninja -C build && ninja -C build install && cd .. && rm -rf ./playerctl ./include || exit 1
sed -i 's#Exec=.*#Exec=playerctl daemon#g' ./share/dbus-1/services/org.mpris.MediaPlayer2.playerctld.service || exit 1

# ADD LIBRARIES
mkdir -p ./shared/lib && mv ./lib/*/* ./shared/lib || exit 1
wget "$LIB4BN" -O ./lib4bin && wget "$SHARUN" -O ./sharun || exit 1
chmod +x ./lib4bin ./sharun
HARD_LINKS=1 ./lib4bin ./bin/* && rm -f ./lib4bin || exit 1

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
DATADIR="${XDG_DATA_HOME:-$HOME/.local/share}"
BIN="${ARGV0#./}"
DAEMON="$(find "$CURRENTDIR" -type f -name 'org*.service' -print -quit 2>/dev/null)"
daemon_name="$(basename "$DAEMON")"
export PATH="$CURRENTDIR/bin:$PATH"
unset ARGV0

_playerctld () {
	if [ ! -e "$DATADIR/dbus-1/services/$daemon_name" ]; then
		mkdir -p "$DATADIR"/dbus-1/services || exit 1
		cp -n "$DAEMON" "$DATADIR"/dbus-1/services || exit 1
		echo "Dbus service installed at $DATADIR/dbus-1/services/$daemon_name"
	fi
	exec "$CURRENTDIR"/bin/playerctl "$@"
}

if [ "$1" = "--daemon" ]; then
	shift
	_playerctld "$@"
elif [ "$BIN" = "playerctld" ]; then
	_playerctld "$@"
else
	exec "$CURRENTDIR"/bin/playerctl "$@"
fi
if [ -z "$1" ]; then
	echo "AppImage commands:"
	echo " \"--daemon\"         Starts playerctld daemon"
	echo "You can also symlink the appimage with the name playerctld"
	echo "to start the daemon by launching that symlink"
fi
EOF
chmod a+x ./AppRun

VERSION=$(./bin/playerctl --version | awk 'FNR==1 {print $1; exit}')

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
wget -q "$APPIMAGETOOL" -O ./appimagetool || exit 1
chmod +x ./appimagetool

# Do the thing!
echo "Making appimage"
./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	./"$APP".AppDir "$APP"-"$VERSION"-"$ARCH".AppImage
mv ./*.AppImage .. && cd .. && rm -rf ./"$APP" || exit 1
echo "All Done!"
