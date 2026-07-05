#!/usr/bin/env nu

def main [] {
    let inventory = open fim.json

    let session_id = (random uuid)

    $inventory | par-each {|file|

        let truncd = (^echo $file.target | b2sum | cut -c1-12)
        let start = (date now)
        let timestamp = (date now | format date "%+")

        let result = (
            ^giant-spellbook
                hash blake3
                $file.target
            | complete
        )

        let finish = (date now)

        let log = {
            timestamp: $timestamp
            session_id: $session_id
            file: $file.target
            start_time: ($start | format date "%+")
            end_time: ($finish | format date "%+")
            exit_code: $result.exit_code
            stdout: ($result.stdout | from json)
            stderr: ($result.stderr | from json)
        }

        $log
        | to json
        | save --append fim_($session_id)_($timestamp | format date "%Y%m%d-%H%M")_($truncd).json

        $log
    }
}
