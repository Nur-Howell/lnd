#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/network/interfaces.sh"
source "$SCRIPT_DIR/ui/menu.sh"
menu

#echo "Working!"