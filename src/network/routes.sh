RESET=$'\e[0m'
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW=$'\e[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

declare -A ROUTE_DATA

fetch_route_info() {
    # 1. Fetch Default Gateway
    # We use awk to find the line starting with 'default' and print the 3rd column
    ROUTE_DATA["DEFAULT_GATEWAY"]=$(ip -4 route 2>/dev/null | awk '/^default/ {print $3}')

    # 2. Fetch IPv4 Local Network Routes (Excluding default)
    local ipv4_dests=($(ip -4 route 2>/dev/null | grep -v '^default' | awk '{print $1}'))
    ROUTE_DATA["IPV4_COUNT"]="${#ipv4_dests[@]}"
    ROUTE_DATA["IPV4_LIST"]="${ipv4_dests[*]}"

    # Store details mapped by IPv4 destination (e.g., ROUTE_DATA["192.168.1.0/24_DEV"])
    for dest in "${ipv4_dests[@]}"; do
        # Safely extract the device (dev) and source IP (src) regardless of column position
        ROUTE_DATA["${dest}_DEV"]=$(ip -4 route show "$dest" 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')
        ROUTE_DATA["${dest}_SRC"]=$(ip -4 route show "$dest" 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
    done

    # 3. Fetch IPv6 Local Network Routes (Excluding default, local, and multicast)
    local ipv6_dests=($(ip -6 route 2>/dev/null | grep -Ev '^(default|local|multicast|unreachable)' | awk '{print $1}'))
    ROUTE_DATA["IPV6_COUNT"]="${#ipv6_dests[@]}"
    ROUTE_DATA["IPV6_LIST"]="${ipv6_dests[*]}"

    # Store details mapped by IPv6 destination
    for dest in "${ipv6_dests[@]}"; do
        ROUTE_DATA["${dest}_DEV"]=$(ip -6 route show "$dest" 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')
    done
}

show_default_route() {
    # Using %s prevents printf from breaking if variables contain special characters
    echo "${YELLOW}=== Default Route ===${RESET}"
    echo ""
    printf "Default Gateway: %s\n\n" "${ROUTE_DATA["DEFAULT_GATEWAY"]:-None}"
}

show_ipv4_routes() {
    local dests=(${ROUTE_DATA["IPV4_LIST"]})

    echo "${YELLOW}=== IPv4 Local Routes ===${RESET}"
    echo ""
    if [[ ${ROUTE_DATA["IPV4_COUNT"]} -eq 0 ]]; then
        echo "No routes found."
        echo ""
        return
    fi

    for dest in "${dests[@]}"; do
        printf "Destination: %s\n" "$dest"
        printf "  Interface: %s\n" "${ROUTE_DATA["${dest}_DEV"]:-Unknown}"
        printf "  Source IP: %s\n\n" "${ROUTE_DATA["${dest}_SRC"]:-None}"
    done
}

show_ipv6_routes() {
    local dests=(${ROUTE_DATA["IPV6_LIST"]})

    echo "${YELLOW}=== IPv6 Local Routes ===${RESET}"
    echo ""
    if [[ ${ROUTE_DATA["IPV6_COUNT"]} -eq 0 ]]; then
        echo "No routes found."
        echo ""
        return
    fi

    for dest in "${dests[@]}"; do
        printf "Destination: %s\n" "$dest"
        printf "  Interface: %s\n\n" "${ROUTE_DATA["${dest}_DEV"]:-Unknown}"
    done
}

display_info() {

fetch_route_info
show_default_route
show_ipv4_routes
show_ipv6_routes

}