RESET=$'\e[0m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[0;33m'
CYAN=$'\e[0;36m'
RED=$'\e[0;31m'

declare -A DNS_DATA

fetch_dns_data() {
    # Reset array
    DNS_DATA=()

    local servers=""
    local domains=""

    # 1. Primary retrieval via resolvectl (systemd-resolved)
    if command -v resolvectl &>/dev/null; then
        servers=$(resolvectl dns 2>/dev/null | awk '{for(i=2;i<=NF;i++) if ($i ~ /^[0-9a-fA-F:.]+$/) print $i}')
        domains=$(resolvectl domain 2>/dev/null | awk '{for(i=2;i<=NF;i++) if ($i !~ /^~/) print $i}')
    fi

    # 2. Fallback to /etc/resolv.conf if resolvectl yields nothing
    if [[ -z "$servers" ]] && [[ -f /etc/resolv.conf ]]; then
        servers=$(awk '/^nameserver/ {print $2}' /etc/resolv.conf)
        domains=$(awk '/^(search|domain)/ {for(i=2;i<=NF;i++) print $i}' /etc/resolv.conf)
    fi

    # Populate state array
    DNS_DATA["SERVERS"]=$(echo "$servers" | xargs)
    DNS_DATA["PRIMARY_SERVER"]=$(echo "$servers" | awk '{print $1}')
    DNS_DATA["DOMAINS"]=$(echo "$domains" | xargs)
}

dns_server_show() {
    fetch_dns_data

    echo -e "${YELLOW}=== Configured DNS Servers ===${RESET}"
    if [[ -n "${DNS_DATA["SERVERS"]}" ]]; then
        for server in ${DNS_DATA["SERVERS"]}; do
            if [[ "$server" == "${DNS_DATA["PRIMARY_SERVER"]}" ]]; then
                echo -e "  * ${GREEN}${server}${RESET} (Primary)"
            else
                echo -e "  * ${server}"
            fi
        done
    else
        echo -e "  ${RED}No active DNS servers detected.${RESET}"
    fi

    echo -e "\n${YELLOW}=== Search Domains ===${RESET}"
    echo -e "  ${DNS_DATA["DOMAINS"]:-None}"
}

dns_resolution_test() {
    local target="${1:-google.com}"
    echo -e "${YELLOW}=== Testing DNS Resolution (${target}) ===${RESET}"

    # Use getent for native system resolution stack test
    local start_time end_time elapsed ip
    start_time=$(date +%s%N)
    ip=$(getent hosts "$target" | awk '{print $1}' | head -n 1)
    end_time=$(date +%s%N)

    if [[ -n "$ip" ]]; then
        elapsed=$(( (end_time - start_time) / 1000000 ))
        echo -e "  Status:   ${GREEN}SUCCESS${RESET}"
        echo -e "  Resolved: ${ip}"
        echo -e "  Latency:  ${YELLOW}${elapsed} ms${RESET}"
    else
        echo -e "  Status:   ${RED}FAILED${RESET} (Unable to resolve ${target})"
    fi
}

dns_reverse_lookup() {
    local ip="$1"
    if [[ -z "$ip" ]]; then
        echo -e "${RED}Error: IP address required for reverse lookup.${RESET}"
        return 1
    fi

    echo -e "${YELLOW}=== Reverse PTR Lookup (${ip}) ===${RESET}"
    local hostname
    hostname=$(getent hosts "$ip" | awk '{print $2}')

    if [[ -n "$hostname" ]]; then
        echo -e "  Hostname: ${GREEN}${hostname}${RESET}"
    else
        echo -e "  Status:   ${YELLOW}No PTR record found${RESET}"
    fi
}

dns_display_info() {

    dns_server_show
    dns_resolution_test "google.com"
    dns_reverse_lookup "8.8.8.8"


}