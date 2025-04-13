#!/bin/bash

configure_plymouth() {
	execute "sudo cp -r ~/.dotfiles/.plymouth-themes/lone /usr/share/plymouth/themes/"
	execute "sudo plymouth-set-default-theme lone"
}

