#!/bin/sh

rm -rf hrmpf-include

# Create an empty zpool.cache to prevent importing at boot
mkdir -p hrmpf-include/etc/zfs
: > hrmpf-include/etc/zfs/zpool.cache

# Copy local repo configs
cp -r /etc/xbps.d hrmpf-include/etc/
# Copy Void installer files
mkdir -p hrmpf-include/root
cp -r /root/void/ hrmpf-include/root/
# Copy local repo files
mkdir -p hrmpf-include/opt
cp -r /opt/localrepo hrmpf-include/opt/

mkdir -p hrmpf-include/etc/runit/runsvdir/default
ln -s /etc/sv/nanoklogd hrmpf-include/etc/runit/runsvdir/default/
ln -s /etc/sv/socklog-unix hrmpf-include/etc/runit/runsvdir/default/socklog-unix
mkdir -p hrmpf-include/etc/sv/socklog-unix/log
printf '%s\n' '#!/bin/sh' 'exec svlogd -ttt /var/log/socklog/* 2>/dev/tty12' > hrmpf-include/etc/sv/socklog-unix/log/run
chmod +x hrmpf-include/etc/sv/socklog-unix/log/run
mkdir -p hrmpf-include/var/log/socklog/tty12
printf '%s\n' '-*' 'e*' 'Eauth.*' 'Eauthpriv.*' > hrmpf-include/var/log/socklog/tty12/config
mkdir -p hrmpf-include/etc/skel hrmpf-include/root
touch hrmpf-include/etc/skel/.vimrc hrmpf-include/root/.vimrc
mkdir -p hrmpf-include/etc/sysctl.d
touch hrmpf-include/etc/sysctl.d/10-void-user.conf

mkdir -p hrmpf-include/usr/bin
sed "s/@@MKLIVE_VERSION@@/$(date -u +%Y%m%d)/g" < installer.sh > hrmpf-include/usr/bin/void-installer
chmod 0755 hrmpf-include/usr/bin/void-installer

./mklive.sh \
	-T "hrmpf live/rescue system" \
	-v linux6.12 \
	-C "loglevel=6 printk.time=1 consoleblank=0" \
	-r https://repo-fastly.voidlinux.org/current \
	-r https://repo-fastly.voidlinux.org/current/nonfree \
	-F 2048 \
	-i zstd \
	-s "xz -Xbcj x86" \
	-B extra/balder10.img \
	-B extra/mhdd32ver4.6.iso \
	-B extra/ipxe.iso \
	-B extra/memtest86+-5.01.iso \
	-B extra/grub2.iso \
	-p "$(grep '^[^#].' hrmpf.packages)" \
	-A "gawk tnftp inetutils-hostname libressl-netcat dash vim-common" \
	-S "acpid binfmt-support dhcpcd gpm sshd" \
	-I hrmpf-include \
	"$@"
