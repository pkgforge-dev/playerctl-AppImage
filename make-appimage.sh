#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q playerctl | awk '{print $2; exit}')
export ARCH VERSION
export OUTPATH=./dist
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DESKTOP=DUMMY
export ICON=DUMMY
export MAIN_BIN=playerctl

# Deploy dependencies
quick-sharun /usr/bin/playerctl /usr/bin/playerctld

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --simple-test ./dist/*.AppImage
