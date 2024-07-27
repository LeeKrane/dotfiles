# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=2500
setopt beep nomatch
unsetopt autocd extendedglob notify
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/krane/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# krane-rc sourcing
source ~/.krane-rc/aliases
source ~/.krane-rc/zsh/krane-rc
source ~/.krane-rc/zsh/paths
source ~/.krane-rc/zsh/local-paths

