#!/usr/bin/env bash
# @name: Docker disk report
# @description: Read-only. Largest images, dangling images and unused volumes first, then the full reclaimable-space summary. Prints the prune commands but never runs them. The final summary can take 30-60s on a host with many containers.
# @os: Ubuntu, Debian
set -u

if ! command -v docker >/dev/null 2>&1; then
    echo "docker not installed on this host"
    exit 0
fi

if ! docker info >/dev/null 2>&1; then
    echo "docker is installed but not reachable by $(id -un)"
    exit 1
fi

# The cheap queries run first so the terminal is never blank while
# `docker system df` walks every layer at the end.
echo "=== filesystem holding docker data ==="
docker_root=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo /var/lib/docker)
echo "  root: $docker_root"
df -h "$docker_root" 2>/dev/null | sed 's/^/  /'

echo
echo "=== 10 largest images ==="
docker images --format '{{.Size}}\t{{.Repository}}:{{.Tag}}' \
    | sort -h -r | head -10 | awk -F'\t' '{printf "  %-10s %s\n", $1, $2}'

echo
echo "=== dangling images ==="
echo "  count: $(docker images -f dangling=true -q | wc -l)"

echo
echo "=== unused volumes ==="
unused=$(docker volume ls -qf dangling=true | wc -l)
echo "  count: $unused"
if [ "$unused" -gt 0 ]; then
    docker volume ls -qf dangling=true | head -15 | sed 's/^/    /'
    [ "$unused" -gt 15 ] && echo "    ... and $((unused - 15)) more"
fi

echo
echo "=== reclaimable summary (walking layers, this takes a moment) ==="
docker system df

echo
echo "=== to reclaim (NOT run by this script) ==="
echo "  docker image prune            # dangling images only"
echo "  docker image prune -a         # every image with no container"
echo "  docker volume prune           # unused volumes - DESTROYS DATA, check the list above"
echo "  docker builder prune          # build cache"
