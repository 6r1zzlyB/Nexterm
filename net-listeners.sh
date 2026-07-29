#!/usr/bin/env bash
# @name: Network listeners
# @description: Read-only. Every listening TCP/UDP socket with its owning process, split into externally-reachable and loopback-only, plus default route, DNS and Tailscale state.
# @os: Ubuntu, Debian
set -u

if ! command -v ss >/dev/null 2>&1; then
    echo "ss not available (install iproute2)"
    exit 1
fi

# Process names require root; without it the columns are simply blank rather
# than the command failing, so run this with sudo for the full picture.
[ "$(id -u)" -ne 0 ] && echo "(not root — process names will be incomplete; re-run with sudo for full detail)"
echo

echo "=== listening, reachable from the network ==="
ss -tulnpH 2>/dev/null \
    | awk '{
        split($5, a, ":"); addr = $5
        if (addr !~ /^127\./ && addr !~ /^\[::1\]/ ) {
            proc = ""
            for (i = 7; i <= NF; i++) proc = proc " " $i
            printf "  %-6s %-26s%s\n", $1, $5, proc
        }
      }' | sort -u

echo
echo "=== listening on loopback only ==="
ss -tulnpH 2>/dev/null \
    | awk '{
        addr = $5
        if (addr ~ /^127\./ || addr ~ /^\[::1\]/) {
            proc = ""
            for (i = 7; i <= NF; i++) proc = proc " " $i
            printf "  %-6s %-26s%s\n", $1, $5, proc
        }
      }' | sort -u | head -30

echo
echo "=== established connection count by peer ==="
# Strip the port from the right, so IPv6 peers survive intact rather than
# collapsing to "[" on a naive split at the first colon.
ss -tnH state established 2>/dev/null \
    | awk '{ peer = $4; sub(/:[0-9]+$/, "", peer); gsub(/^\[|\]$/, "", peer); print peer }' \
    | sort | uniq -c | sort -rn | head -10 | sed 's/^/  /'

echo
echo "=== routing ==="
ip route show default 2>/dev/null | sed 's/^/  /' || echo "  (none)"

echo
echo "=== DNS ==="
if command -v resolvectl >/dev/null 2>&1; then
    resolvectl status 2>/dev/null | grep -E 'Current DNS Server|DNS Servers|DNS Domain' | sed 's/^/  /' | head -6
elif [ -r /etc/resolv.conf ]; then
    grep -E '^(nameserver|search)' /etc/resolv.conf | sed 's/^/  /'
fi

if command -v tailscale >/dev/null 2>&1; then
    echo
    echo "=== tailscale ==="
    tailscale status --peers=false 2>/dev/null | sed 's/^/  /' || echo "  (not running or not logged in)"
    if tailscale status --json 2>/dev/null | grep -q '"ExitNodeOption":true'; then
        echo "  advertising as an exit node"
    fi
fi

exit 0
