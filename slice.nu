#!/usr/bin/env nu

def top-memory [limit:int = 20] {
    ^ps -eo pid,user,%mem,rss,comm --sort=-rss
    | lines
    | skip 1
    | parse --regex '\s*(?<pid>\d+)\s+(?<user>\S+)\s+(?<mem>\S+)\s+(?<rss>\d+)\s+(?<command>.*)'
    | first $limit
    | each {|r|
        {
            pid: ($r.pid | into int)
            user: $r.user
            percent_mem: ($r.mem | into float)
            rss_kb: ($r.rss | into int)
            command: $r.command
        }
    }
}

def logged-in-users [] {
    ^who
    | lines
    | parse "{user} {tty} {date} {time} ({host})"
}

def disks [] {
    ^df -P -h
    | lines
    | skip 1
    | parse --regex '(?<filesystem>\S+)\s+(?<size>\S+)\s+(?<used>\S+)\s+(?<avail>\S+)\s+(?<use>\S+)\s+(?<mount>.+)'
    | each {|r|
        {
            filesystem: $r.filesystem
            size: $r.size
            used: $r.used
            available: $r.avail
            percent_used: $r.use
            mount: $r.mount
        }
    }
}

def remote-connections [] {
    if (which ss | is-not-empty) {
        ^ss -tunpH
        | lines
    } else {
        ^
    }
}

let report = {
    generated_at: (date now)

    timestamps: {
        utc: (date now | format date "%Y-%m-%dT%H:%M:%S.%9fZ")
        local: (date now | format date "%Y-%m-%dT%H:%M:%S.%9f%:z")
        epoch_ns: (date now | format date "%s%9f")
    }

    hostname: (sys host | get hostname)

    kernel: {
        host: (sys host)
    }

    runtime: {
        nushell: (version)
        uptime: (sys host | get uptime)
    }

    cpu: (sys cpu)

    memory: (sys mem)

    disks: (disks)

    top_memory_processes: (top-memory 20)

    logged_in_users: (logged-in-users)

    active_remote_connections: (remote-connections)
}

$report | to json --indent 2
