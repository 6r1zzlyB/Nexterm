#!/usr/bin/env bash
# @name: Failed units & recent errors
# @description: Read-only. Failed systemd units, error-priority journal entries for a bounded window grouped by source and de-duplicated, OOM kills and segfaults, and whether a reboot is pending. Defaults to the last 6h - pass a window as $1, e.g. -24h.
# @os: Ubuntu, Debian
set -u

# Every journal query is bounded. An unbounded `journalctl -b` on a host with
# weeks of uptime takes minutes and is not usable interactively.
SINCE="${1:--6h}"

echo "=== failed units ==="
if command -v systemctl >/dev/null 2>&1; then
    failed=$(systemctl --failed --no-legend --no-pager 2>/dev/null)
    if [ -n "$failed" ]; then
        printf '%s\n' "$failed" | sed 's/^/  /'
    else
        echo "  none"
    fi
    # User units live on a separate bus and are missed by the system query above.
    : "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
    export XDG_RUNTIME_DIR
    ufailed=$(systemctl --user --failed --no-legend --no-pager 2>/dev/null)
    [ -n "$ufailed" ] && { echo "  --- user units ---"; printf '%s\n' "$ufailed" | sed 's/^/  /'; }
else
    echo "  (systemctl unavailable)"
fi

if ! command -v journalctl >/dev/null 2>&1; then
    echo
    echo "(journalctl unavailable — nothing further to report)"
    exit 0
fi

# One pass over the journal, reused for both the grouping and the listing below.
# Three separate journalctl calls cost three full scans of the same window.
errs=$(journalctl -p 3 --since "$SINCE" --no-pager -o short-iso 2>/dev/null | grep -v '^-- ')

echo
echo "=== errors since ${SINCE} ==="
if [ -z "$errs" ]; then
    echo "  none (or no journal access — try sudo, or join the systemd-journal group)"
else
    echo "  total: $(printf '%s\n' "$errs" | wc -l) entries"
    echo
    echo "  -- by source --"
    # short-iso puts "process[pid]:" in field 3 (after timestamp and hostname);
    # dropping the pid groups all instances of a daemon together instead of
    # scattering them across one bucket per restart.
    printf '%s\n' "$errs" | awk '{ src = $3; sub(/\[[0-9]+\]:?$/, "", src); sub(/:$/, "", src); print src }' \
        | sort | uniq -c | sort -rn | head -10 | sed 's/^/    /'
    echo
    echo "  -- distinct messages, most frequent first --"
    # Repeated identical errors are collapsed: 400 copies of one line tells you
    # less than 10 different lines do.
    printf '%s\n' "$errs" | sed 's/^[^ ]* [^ ]* //; s/\[[0-9]\+\]//' \
        | sort | uniq -c | sort -rn | head -12 | cut -c1-160 | sed 's/^/    /'
fi

echo
echo "=== OOM kills / segfaults since ${SINCE} ==="
# journalctl's own -g does the matching inside the reader, far cheaper than
# piping the whole window through grep.
oom=$(journalctl -p 4 --since "$SINCE" --no-pager -g 'out of memory|oom-killer|oom_reaper|segfault' -o short-iso 2>/dev/null | grep -v '^-- ' | tail -10)
if [ -n "$oom" ]; then
    printf '%s\n' "$oom" | sed 's/^/  /'
else
    echo "  none"
fi

echo
echo "=== reboot required ==="
if [ -f /var/run/reboot-required ]; then
    echo "  YES"
    [ -f /var/run/reboot-required.pkgs ] && sed 's/^/    /' /var/run/reboot-required.pkgs
else
    echo "  no"
fi

exit 0
