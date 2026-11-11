#!/usr/bin/env bash
set -euo pipefail

# Run in a separate terminal: this disconnects active Codex sessions.
# Update the CLI, then use it to update and start the daemon/server package.
command -v codex >/dev/null
command -v pgrep >/dev/null

printf '\nUpdating Codex CLI...\n'
codex update
hash -r
codex --version

mapfile -t server_pids < <(
    pgrep -u "$(id -u)" -f '^([^ ]*/)?codex( -c [^ ]+)* app-server --listen( |$)' || true
)

if ((${#server_pids[@]} > 1)); then
    printf 'Multiple Codex servers found (%s); aborting.\n' "${server_pids[*]}" >&2
    exit 1
fi

server_is_running() {
    local state
    state="$(ps -p "$1" -o stat= 2>/dev/null || true)"
    [[ -n "$state" && ! "$state" =~ ^[[:space:]]*[ZX] ]]
}

for server_pid in "${server_pids[@]}"; do
    printf 'Stopping Codex app-server PID %s\n' "$server_pid"
    if ! kill -TERM "$server_pid" 2>/dev/null; then
        if server_is_running "$server_pid"; then
            printf 'Could not stop server PID %s; aborting.\n' "$server_pid" >&2
            exit 1
        fi
    fi

    for ((attempt = 0; attempt < 150; attempt++)); do
        if ! server_is_running "$server_pid"; then
            break
        fi
        sleep 0.2
    done
    if server_is_running "$server_pid"; then
        printf 'Server PID %s has not stopped after 30 seconds; aborting.\n' "$server_pid" >&2
        exit 1
    fi
done

printf '\nUpdating the daemon/server package from the updated CLI...\n'
codex app-server daemon update --from-cli --yes
# Keep the daemon pinned to the updated CLI package. This CLI requires
# --from-cli for daemon updates; a second update without it aborts the script.

printf '\nStarting the updated daemon and app server...\n'
codex app-server daemon start

printf '\nInstalled CLI and running daemon/server versions:\n'
codex --version
codex app-server daemon version
jojo@phantom:~$
