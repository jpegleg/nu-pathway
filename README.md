# nu-pathway 🐡

This repository is a collection of scripts and configs for `nu` [nushell](https://www.nushell.sh/).

## The config

The configuration file for `nu`:

```
cp config.nu ~/.config/nushell/config.nu
```

## The scripts

Included are a collection of scripts.

### command.nu

This is for remote administration with an inventory file named `inventory.json` in the working directory.

```
[
  {
    "name": "db1",
    "dns": "example.com",
    "ip": "192.0.2.13",
    "port": "1800",
    "user": "macadmin",
    "identity": "~/.ssh/admin_14"
  },
  {
    "name": "db2",
    "dns": "example.org",
    "ip": "192.0.2.43",
    "port": "22",
    "user": "macadmin",
    "identity": "~/.ssh/admin_14"
  }
]
```

Once your `inventory.json` is contructed, we can execute commands against all of them in parallel using `command.nu`, capturing the output data to JSON files.

```
nu command.nu "uptime"
```

### slice.nu

This script captures some statistics from the system and outputs JSON to STDOUT.

Support for more operating systems is in progress, right now it works best on linux based systems.

```
nu slice.nu
```
