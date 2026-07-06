#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=2.4.1
STATIC_LIBS_DIR=/tmp/playerctl-static-libs
SRC_DIR=/tmp/playerctl-src

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	autoconf    \
	automake    \
	curl        \
	glib2-devel \
	libtool     \
	meson       \
	ninja

mkdir -p "$STATIC_LIBS_DIR"/lib

build_zlib() (
	echo "Building zlib static..."
	git clone --depth 1 https://github.com/madler/zlib.git /tmp/zlib-src
	cd /tmp/zlib-src
	./configure --static
	make -j"$(nproc)"
	cp libz.a "$STATIC_LIBS_DIR/lib/"
)

build_libffi() (
	echo "Building libffi static..."
	git clone --depth 1 https://github.com/libffi/libffi.git /tmp/libffi-src
	cd /tmp/libffi-src
	./autogen.sh
	./configure --enable-static --disable-shared
	make -j"$(nproc)"
	cp "$ARCH"-*/.libs/libffi.a "$STATIC_LIBS_DIR/lib/"
)

build_util_linux() (
	echo "Building util-linux static (libmount, libblkid)..."
	git clone --depth 1 --branch v2.42.2 https://github.com/util-linux/util-linux.git /tmp/util-linux-src
	cd /tmp/util-linux-src
	./autogen.sh
	./configure \
		--disable-all-programs       \
		--disable-bash-completion    \
		--disable-makeinstall-chown  \
		--disable-makeinstall-setuid \
		--disable-shared             \
		--enable-libblkid            \
		--enable-libmount            \
		--enable-static              \
		--without-python             \
		--without-systemd            \
		--without-udev
	make -j"$(nproc)"
	cp .libs/libmount.a "$STATIC_LIBS_DIR"/lib
	cp .libs/libblkid.a "$STATIC_LIBS_DIR"/lib
)

create_stubs() (
	ar rcs "$STATIC_LIBS_DIR"/lib/libelogind.a
	ar rcs "$STATIC_LIBS_DIR"/lib/libsystemd.a
)

build_playerctl() (
	echo "Cloning playerctl v$VERSION..."
	git clone --depth 1 --branch "v$VERSION" \
		https://github.com/altdesktop/playerctl.git "$SRC_DIR"

	cd "$SRC_DIR"

	echo "Configuring static build..."
	meson setup builddir \
		--default-library=static \
		--prefer-static          \
		--prefix=/usr            \
		-Dintrospection=false    \
		-Dgtk-doc=false          \
		-Dbash-completions=false \
		-Dzsh-completions=false  \
		-Dc_link_args="['-static','-L$STATIC_LIBS_DIR/lib']"

	ninja -C builddir

	strip builddir/playerctl/playerctl builddir/playerctl/playerctld

	cp -v builddir/playerctl/playerctl /usr/bin
	cp -v builddir/playerctl/playerctld /usr/bin
)

build_zlib
build_libffi
build_util_linux
create_stubs
build_playerctl

rm -rf /tmp/zlib-src /tmp/libffi-src /tmp/util-linux-src "$STATIC_LIBS_DIR"

echo "$VERSION" > ~/version
