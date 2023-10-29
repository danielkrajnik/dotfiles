#!/usr/bin/env zsh

[[ "$TTY" == /dev/tty4 ]] && exec Hyprland
# [[ $(tty) = /dev/tty4 ]] && exec startx /home/user1/.config/X11/xinitrc
