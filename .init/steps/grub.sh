#!/bin/bash

configure_grub() {
	execute "sudo mkdir -p /boot/grub2/themes"
	execute "sudo cp -r ~/.dotfiles/.grub-themes/CyberEXS/ /boot/grub2/themes/"
	execute "sudo cp ~/.dotfiles/.grub /etc/default/grub"
	execute "sudo grub2-mkconfig -o /boot/grub2/grub.cfg"
}

