# playerctl-AppImage
Unofficial AppImage of playerctl https://github.com/altdesktop/playerctl

# READ THIS

Works like the regular playerctl, by default running the appimage does the same as running the regular `playerctl` binary.

If you want to start the `playerctld` daemon you have to run the appimage with the `--install-daemon` flag, that is:

`nameofappimage --install-daemon` 

Once that is done, the daemon gets started by passing the `daemon` flag: 

`nameofappimage daemon`

It is possible that this appimage may fail to work with appimagelauncher, I recommend this alternative instead: https://github.com/ivan-hc/AM

This appimage works without fuse2 as it can use fuse3 instead.
