# vpn-config

Add `connect.sh` to `/etc/crontab`

    */1 * * * * root /home/vpn/vpn-scripts/connect.sh

Add firewall config script to `/etc/rc.local`

    /home/vpn/vpn-config/cfg-firewall.sh
    sleep 1 && /home/vpn/vpn-config/connect.sh --silent

