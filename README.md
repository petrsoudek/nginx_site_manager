# Nginx Site Manager (nsm)

NSM is a tool for quickly enabling and disabling Nginx site configs on a Linux server

Stop making symbolic links, start using: nsm -e example.com

## Installation

Paste the content of nsm.sh in /usr/bin/nsm
and give it execution privilleges
```bash
chmod +x /usr/bin/nsm.sh
```

## Usage
List all available sites

```bash
sudo nsm -l
```
Enable site "test_site"
```bash
sudo nsm -e test_site
```
Disable site "test_site"
```bash
sudo nsm -d test_site
```
## License
[GNU General Public License v3.0](https://choosealicense.com/licenses/gpl-3.0/)
