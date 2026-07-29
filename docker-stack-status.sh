#!/usr/bin/env bash
# @name: Docker stack status
# @description: Read-only. Per-stack compose status under /opt/stacks (or the first stack dir found), plus a fleet-wide count of running, stopped and unhealthy containers.
# @os: Ubuntu, Debian
set -u

if ! command -v docker >/dev/null 2>&1; then
    echo "docker not installed on this host"
    exit 0
fi

if ! docker info >/dev/null 2>&1; then
    echo "docker is installed but not reachable by $(id -un) — is the daemon running, and are you in the docker group?"
    exit 1
fi

# `docker compose` (v2 plugin) with a fallback to the legacy docker-compose binary.
if docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
else
    COMPOSE=""
fi

echo "=== container summary ==="
total=$(docker ps -aq | wc -l)
running=$(docker ps -q | wc -l)
printf 'total: %s   running: %s   stopped: %s\n' "$total" "$running" "$((total - running))"

unhealthy=$(docker ps --filter health=unhealthy --format '{{.Names}}')
if [ -n "$unhealthy" ]; then
    echo
    echo "UNHEALTHY:"
    printf '  %s\n' $unhealthy
fi

exited=$(docker ps -a --filter status=exited --format '{{.Names}} ({{.Status}})')
if [ -n "$exited" ]; then
    echo
    echo "EXITED:"
    printf '%s\n' "$exited" | sed 's/^/  /'
fi

echo
echo "=== compose projects (from running containers) ==="
docker ps -a --format '{{.Label "com.docker.compose.project"}}' \
    | grep -v '^$' | sort | uniq -c | sort -rn \
    | awk '{printf "  %-32s %s container(s)\n", $2, $1}' \
    || echo "  (none)"

# Stack directories are the source of truth: a project with no running container
# will not appear above, which is exactly the case worth noticing.
STACK_DIR=""
for d in /opt/stacks /opt/docker /srv/stacks /docker; do
    [ -d "$d" ] && { STACK_DIR="$d"; break; }
done

if [ -n "$STACK_DIR" ] && [ -n "$COMPOSE" ]; then
    echo
    echo "=== stack directories in $STACK_DIR ==="
    for dir in "$STACK_DIR"/*/; do
        [ -d "$dir" ] || continue
        name=$(basename "$dir")
        compose_file=""
        for f in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
            [ -f "${dir}${f}" ] && { compose_file="${dir}${f}"; break; }
        done
        if [ -z "$compose_file" ]; then
            printf '  %-28s no compose file\n' "$name"
            continue
        fi
        up=$(docker ps -q --filter "label=com.docker.compose.project=$name" | wc -l)
        all=$(docker ps -aq --filter "label=com.docker.compose.project=$name" | wc -l)
        if [ "$all" -eq 0 ]; then
            printf '  %-28s DOWN (no containers)\n' "$name"
        elif [ "$up" -eq "$all" ]; then
            printf '  %-28s up %s/%s\n' "$name" "$up" "$all"
        else
            printf '  %-28s DEGRADED %s/%s up\n' "$name" "$up" "$all"
        fi
    done
elif [ -z "$STACK_DIR" ]; then
    echo
    echo "(no stack directory found — looked in /opt/stacks /opt/docker /srv/stacks /docker)"
fi
