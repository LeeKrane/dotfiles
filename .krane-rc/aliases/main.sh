alias c='clear'
alias ls='exa -h'
alias ll='exa -lh'
alias la='exa -Ah'
alias lla='exa -lAh'
alias tree='exa --tree'
alias nv='nvim'
alias cat='bat --color=always'
alias cd='z'
alias zz='z -'
alias lg='lazygit'
alias htop='btop'
alias top='btop'

# fzf
alias fzfp='fzf --preview="bat --color=always {}" --preview-window "~4,+{2}+4/3,<80(up)"'
alias fnv='fzfp --bind "enter:become:nvim {1}"'

alias rf='fzf --disabled --ansi --bind "start:reload:rg --hidden --no-ignore --column --color=always --smart-case {q}" --bind "change:reload:rg --hidden --no-ignore --column --color=always --smart-case {q}" --delimiter : --preview="bat --style=full --color=always --highlight-line {2} {1}" --preview-window "~4,+{2}+4/3,<80(up)" --query "$*"'
alias rfnv='rf --bind "enter:become:nvim {1} +{2}"'

if command -v dnf &> /dev/null; then
	source ~/.dotfiles/.krane-rc/aliases/rebos_dnf.sh
elif command -v pacman &> /dev/null; then
	source ~/.dotfiles/.krane-rc/aliases/rebos_pacman.sh
else
	echo "No supported package manager found!"
	echo "Currently supporting:"
	echo
	echo " - dnf"
	echo " - pacman"
	echo
fi

