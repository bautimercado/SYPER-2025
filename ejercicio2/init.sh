#!/bin/bash


echo "Configuracion server SSH"

apt-get update -qq
apt-get install -y -qq openssh-server iptables moreutils iproute2 rsyslog iputils-ping procps sudo fail2ban

mkdir -p /var/run/sshd
echo 'root:password' | chpasswd

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
sed -i 's/#SyslogFacility AUTH/SyslogFacility AUTH/' /etc/ssh/sshd_config
sed -i 's/#LogLevel INFO/LogLevel VERBOSE/' /etc/ssh/sshd_config
echo "PrintLastLog yes" >> /etc/ssh/sshd_config


echo "Configuracion fail2ban"
cat > /etc/fail2ban/filter.d/sshd-custom.conf << 'EOF'
[Definition]
failregex = ^.*Failed password for .* from <HOST> port \d+ ssh2$

ignoreregex =
EOF

cat > /etc/fail2ban/action.d/iptables-block.conf << 'EOF'
[Definition]
# Simple iptables action for fail2ban: bans by inserting a DROP rule into the INPUT chain
# Uses <ip> and <name> templates provided by fail2ban

actionstart =
actionstop =
actioncheck =

actionban = iptables -I INPUT -s <ip> -j DROP
actionunban = iptables -D INPUT -s <ip> -j DROP
EOF

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 60
maxretry = 5
backend = auto
banaction = iptables-block
action = iptables-block[name=%(__name__)s]

[sshd]
enabled = true
port = ssh
filter = sshd-custom
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
findtime = 60
chain = DOCKER-USER

EOF

mkdir -p /var/log
touch /var/log/auth.log
chmod 666 /var/log/auth.log

echo "Iniciar fail2ban"

fail2ban-server -x &

echo "iniciar server SSH"

exec /usr/sbin/sshd -D -E /dev/stderr 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' >> /var/log/auth.log
