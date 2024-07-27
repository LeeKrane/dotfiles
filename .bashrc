# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
	PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi
unset rc

# PS1="\e[0;35m\u@\h\e[m:\e[0;35m\w\e[m\$ "
PS1="\u@\h:\w\$ "

source ~/.krane-rc/aliases
source ~/.krane-rc/bash/paths
source ~/.krane-rc/bash/local-paths
source ~/.krane-rc/bash/krane-rc
