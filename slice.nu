#!/usr/bin/env nu

let os = (^uname -s | str trim)

def cpu-info [] {
    if $os == "Linux" {
        sys cpu
    } else if $os == "OpenBSD" {
        let model = (^sysctl -n hw.model | str trim)
        let ncpu = (^sysctl -n hw.ncpu | str trim | into int)

        let speed = (
            ^sysctl -n hw.cpuspeed
            | complete
            | if $in.exit_code == 0 {
                $in.stdout | str trim
            } else {
                null
            }
        )

        {
            model: $model
            cores: $ncpu
            speed_mhz: $speed
        }
    } else if $os == "FreeBSD" {
        {
            model: (^sysctl -n hw.model | str trim)
            cores: (^sysctl -n hw.ncpu | str trim | into int)
            clockrate_mhz: (
                ^sysctl -n hw.clockrate
                | complete
                | if $in.exit_code == 0 {
                    $in.stdout | str trim | into int
                } else {
                    null
                }
            )
        }
    } else if $os == "Darwin" {
        {
            model: (^sysctl -n machdep.cpu.brand_string | str trim)
            cores: (^sysctl -n hw.logicalcpu | str trim | into int)
            performance_cores: (
                ^sysctl -n hw.perflevel0.logicalcpu
                | complete
                | if $in.exit_code == 0 {
                    $in.stdout | str trim | into int
                } else {
                    null
                }
            )
        }
    } else {
        null
    }
}

def memory-info [] {
    if $os == "Linux" {
        sys mem
    } else if $os == "OpenBSD" {
        let phys = (^sysctl -n hw.physmem | str trim | into int)

        let vm = (
            ^vmstat
            | lines
            | last
            | split row " "
            | where {|x| $x != ""}
        )

        let free_pages = (
            if ($vm | length) > 4 {
                $vm | get 4 | into int
            } else {
                0
            }
        )

        let page_size = (^sysctl -n hw.pagesize | str trim | into int)

        let free = ($free_pages * $page_size)
        let used = ($phys - $free)

        let swap = (
            ^swapctl -s
            | complete
            | if $in.exit_code == 0 {
                $in.stdout
            } else {
                ""
            }
        )

        {
            total: $phys
            used: $used
            free: $free
            swap: ($swap | str trim)
        }
    } else if $os == "FreeBSD" {
        let total = (^sysctl -n hw.physmem | str trim | into int)

        {
            total: $total
        }
    } else if $os == "Darwin" {
        {
            total: (^sysctl -n hw.memsize | str trim | into int)
        }
    } else {
        null
    }
}

def disks [] {
    let cmd = (
        if $os == "Linux" {
            ^df -P -h
        } else {
            ^df -h
        }
    )

    $cmd
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

def top-memory [limit:int = 20] {
    if $os == "Linux" {
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
    } else {
        let total_mem = (
            if $os == "Darwin" {
                ^sysctl -n hw.memsize | str trim | into int
            } else {
                ^sysctl -n hw.physmem
                | complete
                | if $in.exit_code == 0 {
                    $in.stdout | str trim | into int
                } else {
                    ^sysctl -n hw.realmem | str trim | into int
                }
            }
        )

        ^ps -axo pid,user,rss,comm
        | lines
        | skip 1
        | parse --regex '\s*(?<pid>\d+)\s+(?<user>\S+)\s+(?<rss>\d+)\s+(?<command>.*)'
        | each {|r|
            let rss = ($r.rss | into int)

            {
                pid: ($r.pid | into int)
                user: $r.user
                percent_mem: ((($rss * 1024) * 100.0) / $total_mem)
                rss_kb: $rss
                command: $r.command
            }
        }
        | sort-by rss_kb --reverse
        | first $limit
    }
}

def logged-in-users [] {
    ^who
    | lines
    | each {|l|
        let p1 = ($l | parse "{user} {tty} {date} {time} ({host})")

        if ($p1 | is-not-empty) {
            $p1 | first
        } else {
            let p2 = ($l | parse "{user} {tty} {date} {time}")

            if ($p2 | is-not-empty) {
                ($p2 | first | upsert host "")
            } else {
                null
            }
        }
    }
    | where $it != null
}
def remote-connections [] {
    if $os == "Linux" {
        if (which ss | is-not-empty) {
            ^ss -tunpH
            | lines
        } else {
            ^netstat -tun
            | lines
        }
    } else if $os == "OpenBSD" {
        ^netstat -an
        | lines
    } else if $os == "FreeBSD" {
        ^sockstat -46
        | complete
        | if $in.exit_code == 0 {
            $in.stdout | lines
        } else {
            ^netstat -an | lines
        }
    } else if $os == "Darwin" {
        ^netstat -anv
        | lines
    } else {
        ^netstat -an
        | lines
    }
}

let report = {
    generated_at: (date now)

    timestamps: {
        utc: (date now | format date "%Y-%m-%dT%H:%M:%S.%9fZ")
        local: (date now | format date "%Y-%m-%dT%H:%M:%S.%9f%:z")
        epoch_ns: (date now | format date "%s%9f")
    }

    system: {
        os: $os
        host: (sys host)
    }

    runtime: {
        nushell: (version)
        uptime: (
            if $os == "Linux" {
                sys host | get uptime
            } else {
                sys host
                | get uptime?
                | default (
                    ^uptime
                    | str trim
                )
            }
        )
    }

    cpu: (cpu-info)

    memory: (memory-info)

    disks: (disks)

    top_memory_processes: (top-memory 20)

    logged_in_users: (logged-in-users)

    active_remote_connections: (remote-connections)
}

$report | to json --indent 2
