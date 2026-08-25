#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/network/interfaces.sh"
source "$SCRIPT_DIR/ui/menu.sh"
source "$SCRIPT_DIR/network/routes.sh"
menu
#menu

#echo "Working!"