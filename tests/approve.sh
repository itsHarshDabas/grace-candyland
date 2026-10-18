#!/bin/sh
# Round-trip test for grace-approve against a running Grace shell (run it inside the session).
# Answers the way the shell's buttons do, by writing to the request FIFO, and checks exit codes.
set -u
shell=${GRACE_SHELL:-/usr/share/grace-candyland/shell}
dir=$XDG_RUNTIME_DIR/grace/approvals
fail=0

check() { # check STATUS WANT LABEL
    if [ "$1" = "$2" ]; then
        echo "ok: $3 -> $1"
    else
        echo "FAIL: $3 -> $1, want $2"
        fail=1
    fi
}

ask() { # ask ANSWER WANT
    grace-approve "Test agent" "echo hi" /tmp &
    pid=$!
    sleep 1
    n=$(qs -p "$shell" ipc call approvals count 2>/dev/null | tail -n 1)
    check "$n" 1 "pending requests"
    for fifo in "$dir"/*; do
        printf %s "$1" >"$fifo"
    done
    wait "$pid"
    check $? "$2" "$1"
}

ask allow 0
ask deny 1
XDG_RUNTIME_DIR=/nonexistent grace-approve a b 2>/dev/null
check $? 2 "no runtime dir"
exit $fail
