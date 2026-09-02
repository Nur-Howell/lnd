# 2 September 2026

Added the logic for `dns.sh` bash script. The logic contains 4 functions. Each of which are important for functionality of `dns.sh`.

---

## Functions
```
fetch_dns_data() {...}
```
* **State Purge & Scope Management (`DNS_DATA=()`, `local ...`):**  
  Flushes all existing key-value pairs from the `DNS_DATA` associative array to purge stale memory entries. Local declarations (`local servers=""`, `local domains=""`) constrain scope to the function context, preventing variable leak into the parent shell environment.

* **Binary Discovery (`command -v resolvectl &>/dev/null`):**  
  Probes `$PATH` using the shell built-in `command -v` to check for `systemd-resolved` support without spawning subshell overhead (e.g., `which`). Standard output and standard error are silenced to `/dev/null`.

* **Primary DNS Query (`resolvectl dns ...`):**  
  Queries `systemd-resolved` over IPC/D-Bus. Streams output through `awk`, which iterates over fields past `$1` and uses regex (`/^[0-9a-fA-F:.]+$/`) to strip interface labels (e.g., `Link 2 (eth0):`) and isolate valid IPv4/IPv6 address strings.

* **Routing Domain Query (`resolvectl domain ...`):**  
  Queries configured domain search paths. Filters out routing-only domains starting with a tilde (`!~ /^~/`) to ensure only actual search/lookup domains are captured.

* **Static Resolver Fallback (`if [[ -z "$servers" ]] && [[ -f /etc/resolv.conf ]]`):**  
  Defensive boundary check. If `systemd-resolved` returns no nameservers or is absent, the execution path falls back to inspecting the physical `/etc/resolv.conf` file (essential for containerized or non-systemd Linux environments).

* **Fallback Stream Parsing (`awk '/^nameserver/'`, `awk '/^(search|domain)/'`):**  
  Parses legacy resolver configurations managed by `glibc`/`musl`:
  * Extracts field 2 of lines starting with `nameserver` to capture active IP addresses.
  * Iterates across fields on `search` or `domain` lines to extract fallback domain search paths.

* **Array State Population (`DNS_DATA[...]`):**  
  Serializes and commits ingested values into process memory:
  * `DNS_DATA["SERVERS"]`: Pipes values through `xargs` to flatten multi-line outputs into a single space-delimited string for clean loop iteration.
  * `DNS_DATA["PRIMARY_SERVER"]`: Uses `awk '{print $1}'` to isolate the top-priority nameserver.
  * `DNS_DATA["DOMAINS"]`: Flattens search domains into a space-delimited string.
```
dns_server_show() {...}
```
* **State Refresh (`fetch_dns_data`):**  
  Invokes the ingestion function first to guarantee that shell memory contains up-to-date system data before rendering output.

* **Array Memory Check (`if [[ -n "${DNS_DATA["SERVERS"]}" ]]`):**  
  Verifies that the `SERVERS` key holds a non-empty string before attempting display operations.

* **Word-Splitting Iteration (`for server in ${DNS_DATA["SERVERS"]}`):**  
  Leverages Bash word-splitting across the space-separated string of IP addresses to process each nameserver entry individually.

* **Primary Server Designation (`if [[ "$server" == "${DNS_DATA["PRIMARY_SERVER"]}" ]]`):**  
  Compares the current loop item against the primary resolver key. If it matches, it applies green ANSI highlighting and appends a `(Primary)` label; secondary resolvers are printed normally.

* **Error Handling:**  
  If no nameservers were captured during ingestion, it branch-prints a red alert indicating no active DNS servers were detected on the host.

* **Parameter Expansion Fallback (`${DNS_DATA["DOMAINS"]:-None}`):**  
  Uses parameter expansion to output configured search/routing domains, or cleanly defaults to printing `None` without requiring additional `if/else` boilerplate.
```
dns_resolution_test() {...}
```
* **Default Argument Expansion (`${1:-google.com}`):**  
  Assigns the first CLI argument to `target`. If `$1` is unassigned or empty, Bash parameter expansion automatically defaults to `google.com`.

* **High-Precision Clock Capture (`start_time=$(date +%s%N)`):**  
  Pulls a nanosecond-level timestamp from the kernel system clock immediately before executing the lookup.

* **NSS Stack Resolution (`getent hosts "$target"`):**  
  Triggers `glibc`'s Name Service Switch (NSS) lookup chain (`/etc/nsswitch.conf`). It tests the actual OS resolution stack (evaluating `/etc/hosts`, `mDNS`, and active DNS resolvers in system-defined order) rather than querying port 53 directly like `dig`.

* **Output Stream Extraction (`awk ... | head -n 1`):**  
  Extracts column 1 (the resolved IP address) and uses `head -n 1` to capture only the primary record if multiple IP addresses are returned.

* **Kernel Clock Delta (`end_time=$(date +%s%N)`):**  
  Captures the post-resolution timestamp immediately after the process exits.

* **In-Memory Latency Math (`$(( ... / 1000000 ))`):**  
  Subtracts `start_time` from `end_time` and divides by 1,000,000 using native Bash integer arithmetic to calculate latency in milliseconds without spawning an external calculator tool (`bc`).

* **Conditional Output Branching:**  
  Checks if `$ip` contains a string (`if [[ -n "$ip" ]]`):
  * **Success:** Displays a green success banner, the resolved IP, and the elapsed latency in yellow.
  * **Failure:** Displays a red error status indicating the system failed to resolve the domain.
```
dns_reverse_lookup() {...}
```
## Operational Breakdown

* **Input Validation:**  
  Evaluates whether an IP address argument (`$1`) was supplied upon invocation. If missing, it prints an error message in red ANSI formatting and immediately terminates function execution with return code `1` (`return 1`) to prevent unhandled subshell execution or null parameter errors.

* **NSS Querying (`getent hosts "$ip"`):**  
  Queries the `glibc` Name Service Switch (NSS) interface directly rather than issuing a raw UDP packet via `dig -x` or `host`. This checks `/etc/hosts` first before querying active DNS resolvers, accurately matching native system-level process behavior.

* **Stream Parsing (`awk '{print $2}'`):**  
  `getent hosts <ip>` outputs data in the standard format `1.1.1.1 one.one.one.one`. The downstream `awk` pipeline isolates field 2 (`$2`) to extract the canonical hostname while discarding the IP address and any secondary domain aliases.

* **Conditional Output Branching:**  
  Tests if the `$hostname` variable contains a non-empty string (`if [[ -n "$hostname" ]]`):
  * **Found:** Displays the mapped canonical domain name in green ANSI formatting.
  * **Not Found:** Gracefully displays a yellow status message indicating no PTR record exists in local caches or remote DNS zone files.