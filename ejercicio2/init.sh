#!/bin/bash


echo "Configuracion server SSH"

apt-get update -qq
apt-get install -y -qq openssh-server iptables iproute2 rsyslog iputils-ping procps sudo fail2ban

mkdir -p /var/run/sshd
echo 'root:password' | chpasswd

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
sed -i 's/#SyslogFacility AUTH/SyslogFacility AUTH/' /etc/ssh/sshd_config
sed -i 's/#LogLevel INFO/LogLevel VERBOSE/' /etc/ssh/sshd_config
echo "PrintLastLog yes" >> /etc/ssh/sshd_config


echo "Configuracion fail2ban"

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 2
backend = auto

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 2
bantime = 3600
findtime = 600
EOF

mkdir -p /var/log
touch /var/log/auth.log
chmod 666 /var/log/auth.log

echo "Iniciar fail2ban"

fail2ban-server -x &

echo "iniciar server SSH"

exec /usr/sbin/sshd -D -E /var/log/auth.log
