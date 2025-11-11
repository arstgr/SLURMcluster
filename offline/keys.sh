#!/bin/bash

echo "PASTE YOUR SSH PUBLIC KEY HERE" > ~/.ssh/id_rsa.pub

chmod 644 ~/.ssh/id_rsa.pub

echo "-----BEGIN RSA PRIVATE KEY-----
PASTE THE PRIVATE KEY HERE
-----END RSA PRIVATE KEY-----" > ~/.ssh/id_rsa

chmod 600 ~/.ssh/id_rsa

cat <<EOF > ~/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOD
