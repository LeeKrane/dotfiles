#!/bin/bash

choose_installation_mode() {
	local prompt="Choose installation mode:\n"
	local options=("Partial (default: YES)" "Partial (default: NO)" "Full (do everything)")
	local selected=0
	local num_options=${#options[@]}

	tput civis

	while true; do
		echo -e "${BLUE}$prompt${NC}"
		for i in $(seq 0 $((num_options - 1))); do
			if [ "$i" -eq "$selected" ]; then
				echo -e "${GREEN}> ${options[$i]}${NC}"
			else
				echo "  ${options[$i]}"
			fi
		done

		read -s -n 1 key
		case "$key" in
		A) selected=$(((selected - 1 + num_options) % num_options)) ;;
		B) selected=$(((selected + 1) % num_options)) ;;
		"") printf $CLEAR_7_LINES; tput cnorm; return $selected ;;
		q) cleanup; exit 1 ;;
		esac

		printf $CLEAR_5_LINES
	done
}

choose_single_checkbox() {
	local prompt="$1"
	local checked="$2"

	while true; do
		printf $CLEAR_LINE
		echo -n -e "${GREEN}> [${checked}] $prompt${NC}"

		key=$(dd bs=1 count=1 2>/dev/null)

		case "$key" in
		" ") [[ "$checked" == " " ]] && checked="x" || checked=" " ;;
		$'\r') printf $CLEAR_LINE; echo -n "  [${checked}] $prompt"
			[[ "$checked" == "x" ]] && return 0 || return 1 ;;
		q) cleanup; exit 1 ;;
		esac
	done
}

