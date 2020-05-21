# vpn-config

A set of scripts for setting up a VPN gateway. Test with Ubuntu 20.04 LTS server and Private Internet Access.

    git clone https://github.com/andygock/vpn-config.git
    cd vpn-config

Download Private Internet Access `.ovpn` files. These will be saved to `ovpn/`.

    ./get-pia-config.sh

## Credentials

Create a file `credentials.txt` with two lines containing your login credentials for OpenVPN.

    username
    password

Protect the file from other users:

    chmod 0600 credentials.txt

## Add scripts to crontab and start up

Add `connect.sh` to `/etc/crontab`

    */1 * * * * root /home/vpn/vpn-scripts/connect.sh

Add firewall config script to `/etc/rc.local`

    /home/vpn/vpn-config/cfg-firewall.sh
    sleep 1 && /home/vpn/vpn-config/connect.sh --silent

