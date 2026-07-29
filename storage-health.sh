#!/usr/bin/env bash
# @name: Storage health
# @description: Read-only. Disk and inode pressure, NFS/CIFS mounts probed with a timeout so a dead server cannot hang the session, plus mdraid and SMART status when available.
# @os: Ubuntu, Debian
set -u

WARN_PCT=85

echo "=== filesystem usage ==="
df -h -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null

echo
echo "=== over ${WARN_PCT}% used ==="
df -P -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null \
    | awk -v w="$WARN_PCT" 'NR>1 { gsub(/%/,"",$5); if ($5+0 >= w) printf "  %-28s %s%% used, %s avail\n", $6, $5, $4 }' \
    | grep . || echo "  none"

echo
echo "=== inode pressure (over ${WARN_PCT}%) ==="
df -Pi -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null \
    | awk -v w="$WARN_PCT" 'NR>1 { gsub(/%/,"",$5); if ($5+0 >= w) printf "  %-28s %s%% inodes used\n", $6, $5 }' \
    | grep . || echo "  none"

echo
echo "=== network mounts ==="
# A hung NFS server makes df/stat block indefinitely, so every probe is wrapped
# in `timeout`. Reading /proc/mounts never touches the remote server.
net_mounts=$(awk '$3 ~ /^(nfs|nfs4|cifs|smb3)$/ { print $2 "\t" $1 "\t" $3 }' /proc/mounts)
if [ -z "$net_mounts" ]; then
    echo "  none"
else
    printf '%s\n' "$net_mounts" | while IFS=$'\t' read -r mp src fstype; do
        if timeout 5 stat -f "$mp" >/dev/null 2>&1; then
            avail=$(timeout 5 df -h "$mp" 2>/dev/null | awk 'NR==2 {print $4 " avail, " $5 " used"}')
            printf '  OK      %-18s %-8s %s  (%s)\n' "$mp" "$fstype" "$src" "${avail:-?}"
        else
            printf '  TIMEOUT %-18s %-8s %s  <-- server not responding\n' "$mp" "$fstype" "$src"
        fi
    done
fi

if [ -r /proc/mdstat ] && grep -qE '^md[0-9]' /proc/mdstat 2>/dev/null; then
    echo
    echo "=== mdraid ==="
    grep -E '^md[0-9]|blocks|recovery|resync' /proc/mdstat | sed 's/^/  /'
fi

if command -v smartctl >/dev/null 2>&1; then
    echo
    echo "=== SMART ==="
    for dev in $(lsblk -dno NAME,TYPE 2>/dev/null | awk '$2=="disk" {print $1}'); do
        health=$(timeout 10 smartctl -H "/dev/$dev" 2>/dev/null | awk -F: '/overall-health|SMART Health Status/ {gsub(/^[ \t]+/,"",$2); print $2}')
        printf '  %-10s %s\n' "$dev" "${health:-unavailable (needs root, or not supported on this bus)}"
    done
fi
