#!/usr/bin/env bash
# @name: Host quick info
# @description: One-glance host summary — kernel, uptime/load, memory, disk, and (if present) running Docker containers.
# @os: Ubuntu, Debian
set -u

echo "=== host ==="
hostname
uname -srm

echo
echo "=== uptime / load ==="
uptime

echo
echo "=== memory ==="
free -h 2>/dev/null || echo "(free unavailable)"

echo
echo "=== disk (real filesystems) ==="
df -h -x tmpfs -x devtmpfs 2>/dev/null | sed -n '1,8p'

if command -v docker >/dev/null 2>&1; then
  echo
  echo "=== docker (running containers) ==="
  docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null | head -40 || echo "(docker present but not accessible by this user)"
fi
