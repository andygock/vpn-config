#!/bin/bash

HOME_DIR=/home/vpn

CONFIG_DIR=$HOME_DIR/vpn-config/ovpn
CREDENTIALS=$HOME_DIR/pia_credentials.txt

if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
fi

# get .ovpn files from vendor
curl -o pia-config.zip https://www.privateinternetaccess.com/openvpn/openvpn-strong.zip

unzip -o pia-config.zip -d "$CONFIG_DIR"
rm -f pia-config.zip

# delete auth-user-pass line, which causes a interactive user/pass prompt
# we'll be using --auth-user-pass FILE in our openvpn options
echo "Modifying *.ovpn files..."
find "$CONFIG_DIR" -name "*.ovpn" -exec sed -i'' "/auth-user-pass/d" {} \;
