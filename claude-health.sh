#!/usr/bin/env bash
# @name: Claude Code health check (JUMP-02)
# @description: Read-only diagnostic — service active/enabled state, recent journal lines, and screen session presence.
# @os: Ubuntu, Debian
set -u
# Allow `systemctl --user` to reach the user bus over a non-login SSH session (lingering must be enabled).
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
export XDG_RUNTIME_DIR

echo "=== claude-screen.service ==="
printf 'active : %s\n' "$(systemctl --user is-active   claude-screen.service 2>&1)"
printf 'enabled: %s\n' "$(systemctl --user is-enabled  claude-screen.service 2>&1)"

echo
echo "=== recent logs (last 15) ==="
journalctl --user -u claude-screen.service -n 15 --no-pager 2>/dev/null || echo "(no journal access)"

echo
echo "=== screen sessions ==="
screen -ls 2>/dev/null || echo "(no screen sessions)"
