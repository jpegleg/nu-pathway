#!/usr/bin/env nu

def main [command: string] {
    let inventory = open inventory.json
    let session_id = (random uid)

    $inventory | par-each {|host|

        let start = (date now)
        let timestamp = (date now | format date "%+")

        let result = (
            ^ssh
                -i ($host.identity)
                -p ($host.port | into string)
                $"($host.user)@($host.dns)"
                $command
            | complete
        )

        let finish = (date now)

        let log = {
            timestamp: $timestamp
            session_id: $session_id
            remote: $host.name
            dns: $host.dns
            ip: $host.ip
            ssh_port: $host.port
            start_time: ($start | format date "%+")
            end_time: ($finish | format date "%+")
            command: $command
            exit_code: $result.exit_code
            stdout: $result.stdout
            stderr: $result.stderr
        }

        $log
        | to json
        | save --append commands.log

        $log
    }
}
