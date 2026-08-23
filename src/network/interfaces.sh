RESET=$'\e[0m'
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW=$'\e[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

declare -A NET_DATA

fetch_interface_info() {
    # 1. Get non-loopback interface list and count
    local interfaces=($(ip link | grep -E '^[0-9]+:' | awk '{print $2}' | tr -d ':' | grep -v '^lo$'))
    NET_DATA["COUNT"]="${#interfaces[@]}"
    NET_DATA["LIST"]="${interfaces[*]}"

    # Store host IPs directly in NET_DATA to avoid calling hostname -I later
    NET_DATA["HOST_IP"]=$(hostname -I)

    # 2. Iterate through each interface to store IPs and Traffic Stats
    for int in "${interfaces[@]}"; do
        # Fetch IPv4 and IPv6 for this specific interface
        NET_DATA["${int}_IPV4"]=$(ip -4 addr show "$int" | grep -E 'inet [0-9]' | awk '{print $2}')
        NET_DATA["${int}_IPV6"]=$(ip -6 addr show "$int" | grep -E 'inet6 ' | awk '{print $2}')

        # Combined single call to 'ip -s link' to fetch both RX and TX data in one pass
        local stats=$(ip -s link show "$int")

        # Extract RX bytes (Column 1) and RX packets (Column 2)
        local rx_line=$(echo "$stats" | grep -A 1 "RX:" | tail -n 1)
        NET_DATA["${int}_RX_BYTES"]=$(echo "$rx_line" | awk '{print $1}')
        NET_DATA["${int}_RX_PACKETS"]=$(echo "$rx_line" | awk '{print $2}')

        # Extract TX bytes (Column 1) and TX packets (Column 2)
        local tx_line=$(echo "$stats" | grep -A 1 "TX:" | tail -n 1)
        NET_DATA["${int}_TX_BYTES"]=$(echo "$tx_line" | awk '{print $1}')
        NET_DATA["${int}_TX_PACKETS"]=$(echo "$tx_line" | awk '{print $2}')
    done
}

host_show() {
    
    echo "${YELLOW}=== Host Information ===${RESET}"
    echo ""
    printf "Current Host IP: %s\n\n" "${NET_DATA["HOST_IP"]}"

}

interfaces_show() {

    echo "${YELLOW}=== Interfaces Overview ===${RESET}"
    echo ""
    printf "Interfaces:\n%s\n" "${NET_DATA["LIST"]}"
    printf "Interface Count: %s\n" "${NET_DATA["COUNT"]}"
echo ""

}

interfaces_address_show() {

    local interfaces=(${NET_DATA["LIST"]})

    echo "${YELLOW}=== IP Addresses Overview ===${RESET}"
    echo ""
    for int in "${interfaces[@]}"; do
        echo "Interface: $int"
        echo "  IPv4: ${NET_DATA["${int}_IPV4"]:-None}"
        echo "  IPv6: ${NET_DATA["${int}_IPV6"]:-None}"
        echo ""
    done

}

packets_show() {

    local interfaces=(${NET_DATA["LIST"]})

    echo "${YELLOW}=== Network Traffic Overview ===${RESET}"
    echo ""
    for int in "${interfaces[@]}"; do
        echo "Interface: $int"
        # Used fallback :-0 in case an interface has 0 bytes/packets or empty reads
        echo "  RX: ${NET_DATA["${int}_RX_BYTES"]:-0} bytes (${NET_DATA["${int}_RX_PACKETS"]:-0} packets)"
        echo "  TX: ${NET_DATA["${int}_TX_BYTES"]:-0} bytes (${NET_DATA["${int}_TX_PACKETS"]:-0} packets)"
        echo ""
    done

}

info_show() {
    fetch_interface_info
    host_show
    interfaces_show
    interfaces_address_show
    packets_show
}


