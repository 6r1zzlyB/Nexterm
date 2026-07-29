#!/usr/bin/env bash
# @name: GPU & transcode status
# @description: Read-only. NVIDIA GPU utilisation, temperature and encoder/decoder load, the processes holding the GPU, and any active Plex/Jellyfin/ffmpeg transcodes with their scratch-directory usage.
# @os: Ubuntu, Debian
set -u

if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "nvidia-smi not present — no NVIDIA driver on this host"
else
    echo "=== GPU ==="
    nvidia-smi --query-gpu=name,driver_version,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total \
        --format=csv,noheader 2>/dev/null \
        | awk -F', ' '{printf "  %s\n  driver %s | %s C | gpu %s | mem %s (%s / %s)\n", $1, $2, $3, $4, $5, $6, $7}'

    # Encoder/decoder utilisation is the number that actually matters for
    # transcoding; it is not part of the default nvidia-smi table.
    enc=$(nvidia-smi --query-gpu=utilization.encoder,utilization.decoder --format=csv,noheader 2>/dev/null)
    [ -n "$enc" ] && echo "  encoder/decoder: $enc"

    echo
    echo "=== processes on the GPU ==="
    procs=$(nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader 2>/dev/null)
    if [ -n "$procs" ]; then
        printf '%s\n' "$procs" | sed 's/^/  /'
    else
        echo "  none (note: video encode/decode clients may not appear here)"
    fi
fi

echo
echo "=== transcode processes ==="
# Match the transcoder binaries directly; Plex ships its own ffmpeg build.
tp=$(ps -eo pid,etime,pcpu,comm,args --no-headers 2>/dev/null \
     | grep -Ei 'Plex Transcoder|plex-transcoder|jellyfin-ffmpeg|/ffmpeg' \
     | grep -v grep)
if [ -n "$tp" ]; then
    printf '%s\n' "$tp" | awk '{printf "  pid %-8s up %-10s cpu %-6s %s\n", $1, $2, $3, $4}'
    echo "  count: $(printf '%s\n' "$tp" | wc -l)"
else
    echo "  none active"
fi

echo
echo "=== transcode scratch space ==="
found=0
for d in /transcode /tmp/transcode /dev/shm /var/lib/plexmediaserver/tmp /config/transcode; do
    if [ -d "$d" ]; then
        used=$(df -h "$d" 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
        printf '  %-34s %s\n' "$d" "${used:-?}"
        found=1
    fi
done
[ "$found" -eq 0 ] && echo "  no known transcode directory found"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo
    echo "=== media containers ==="
    docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null \
        | grep -Ei 'plex|jellyfin|emby|tautulli|sonarr|radarr|prowlarr' \
        | awk -F'\t' '{printf "  %-22s %s\n", $1, $2}' \
        || echo "  none running"
fi
