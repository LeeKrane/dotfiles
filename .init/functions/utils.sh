#!/bin/bash

show_help() {
	echo -e "${BLUE}Usage: $0 [options]${NC}"
	echo -e "${BLUE}Options:${NC}"
	echo -e "  -d, --dry-run   Perform a dry run, showing commands without executing them."
	echo -e "  -h, --help      Display this help message."
}

cleanup() {
	stty "$OLD_SETTINGS"
	tput cnorm
	echo -e "\n\n${RED}Script interrupted.${NC}"
	exit 1
}

execute() {
	local command="$1"
	echo -n -e " ${GREEN}>${NC} "
	echo "$command"
	if ! $dry_run; then
		eval "$command"
	fi
}

execute_non_verbose() {
	local command="$1"
	if ! $dry_run; then
		eval "$command"
	fi
}

