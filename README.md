# playerctl-AppImage
Unofficial AppImage of playerctl https://github.com/altdesktop/playerctl

# READ THIS

Even though the playerctld daemon is shipped inside the appimage, it cannot be launched normally As the daemon depends on a dbus service to be launched, and it seems the only way to add the dbus service needs root privileges. 
