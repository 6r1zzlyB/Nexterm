# nexterm-snippets

Scripts and snippets source for [Nexterm](https://github.com/gnmyt/Nexterm), used
by Saint Denis Enterprises. Add the raw URL of this repo as a **Source** in
Nexterm and everything below appears in the Scripts and Snippets menus.

## Contents

### Scripts (`.sh`) — run as a file on the server

| File | What it reports |
|---|---|
| `docker-stack-status.sh` | Per-stack compose status under `/opt/stacks`, plus running/stopped/unhealthy counts |
| `docker-disk-report.sh` | Largest images, dangling images, unused volumes, then reclaimable space |
| `storage-health.sh` | Disk and inode pressure, NFS/CIFS mounts probed with a timeout, mdraid, SMART |
| `gpu-transcode.sh` | NVIDIA utilisation and encoder load, transcode processes, scratch space, media containers |
| `net-listeners.sh` | Listening sockets split by reachability, top peers, routing, DNS, Tailscale |
| `journal-errors.sh` | Failed units, de-duplicated journal errors for a bounded window, OOM kills, reboot-required |
| `host-quickinfo.sh` | One-glance host summary — kernel, uptime, memory, disk, containers |
| `claude-health.sh` | Claude Code service diagnostic on JUMP-02 |

### Snippets (`.snippet`) — pasted into the terminal

| File | What it does |
|---|---|
| `docker-unhealthy.snippet` | Only the containers that are unhealthy, exited or restarting |
| `apt-updates.snippet` | Pending and security update counts, plus reboot-required |
| `top-consumers.snippet` | Top 10 processes by CPU and by resident memory |
| `disk-hogs.snippet` | Largest directories and files on `/` |
| `claude-status.snippet` | Claude Code service state on JUMP-02 |
| `claude-new.snippet` | Start the Claude Code session if it is not running |
| `claude-restart.snippet` | Restart Claude Code, refusing if run from inside its own screen session |
| `jump02-claude.snippet` | Attach to the persistent Claude Code screen session |

Everything here is **read-only**. `docker-disk-report.sh` prints the prune
commands but never runs them.

## File format

Nexterm decides what a file is from its **extension**, not its location:

- Scripts: `.sh` `.bash` `.zsh` `.fish` `.ps1`
- Snippets: `.txt` `.snippet` `.cmd`
- Themes: `.theme.css`

Metadata lives in leading `#` comments:

```sh
# @name: Largest files
# @description: Find the 10 largest files on the system.
# @os: Ubuntu, Debian
```

| Tag | Notes |
|---|---|
| `@name` | Display name in the Nexterm UI. Defaults to the filename. |
| `@description` | Shown under the name in the menu. |
| `@os` | Comma-separated. Omit to show the entry on every host. |

### `@os` must use Nexterm's own OS names

This is the easy one to get wrong. Nexterm normalises a server's detected OS to
one of a fixed list and then does an exact `filter.includes(serverOsName)`
match. A value that is not on the list — `linux`, for example — matches nothing,
and the entry silently disappears from every host whose OS was detected.

Valid values:

```
Ubuntu · Debian · Alpine Linux · Fedora · CentOS · Red Hat · Rocky Linux
AlmaLinux · openSUSE · Arch Linux · Manjaro · Gentoo · NixOS · Proxmox VE
```

`Proxmox VE` is special: an entry filtered to *only* `Proxmox VE` is hidden from
regular servers, and PVE entries only show entries that either name `Proxmox VE`
or carry no `@os` at all.

## NTINDEX

Nexterm fetches `NTINDEX` from the repo root and syncs only what it lists — a
file that is not in the manifest is invisible, however valid it is.

```
<relative/path>@<md5hash>
```

The hash is a change-detection cache. It must be the md5 of the file **as
served**, i.e. the LF-committed bytes, so compute it from git rather than from a
CRLF working copy:

```bash
for f in *.sh *.snippet; do
    printf '%s@%s\n' "$f" "$(git show ":$f" | md5sum | cut -d' ' -f1)"
done
```

Regenerate `NTINDEX` whenever a file is added or changed, or Nexterm will keep
serving the previous version.

## Conventions

- Read-only by default. Anything destructive prints the command instead of running it.
- Guard every optional tool with `command -v` and degrade with a clear message.
- Bound anything that scans logs or walks a filesystem — an unbounded
  `journalctl -b` on a long-uptime host takes minutes.
- Wrap NFS probes in `timeout`; a hung server otherwise blocks the whole session.
- Never require root. Say what is missing without it, and keep working.
