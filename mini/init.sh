#!/dumb-init /bin/bash

net=0
cgroups=1

echo "INIT: set up proc, dev, sys, tmp"
/usr/bin/mount -t proc none /proc
/usr/bin/mount -t sysfs none /sys
/usr/bin/mount -t tmpfs none /tmp
/usr/bin/mkdir -p /dev/pts
/usr/bin/mkdir -p /dev/mapper
/usr/bin/ln -s /proc/self/fd /dev/fd
/usr/bin/mount -t devpts none /dev/pts
/usr/bin/mount -t debugfs none /sys/kernel/debug
if [ "$cgroup" = 1 ]; then
	/usr/bin/mount -t cgroup none /sys/fs/cgroup
	/usr/bin/mount -t cgroup2 none /sys/fs/cgroup/unified
fi

ip a add 127.0.0.1/8 dev lo

export PS1='\u@\h:\w\$ '
export PATH=/bin:/sbin:/usr/bin/:/usr/sbin
export SHELL=/bin/bash

# resize terminal
resize() {
  old=$(stty -g)
  stty -echo
  printf '\033[18t'
  IFS=';' read -d t _ rows cols _
  stty "$old"
  stty cols "$cols" rows "$rows"
}

# 2nd serial console
#/dumb-init /sbin/agetty -a root ttyS1 linux &

if [ "$net" = 1 ]; then
	echo "INIT: remount / read-write"
	mount -o remount,rw /
	echo "INIT: set up networking, ssh"
	/usr/bin/ifconfig eth0 up
	/sbin/dhclient eth0
	if ! /usr/sbin/sshd; then
		/usr/sbin/sshd-gen-keys-start
		/usr/sbin/sshd
	fi
fi

if [ -f '/autorun.sh' ]; then
	full=$(readlink -f /autorun.sh)
	echo "INIT: autorun.sh ($full) found, starting in 3 seconds, press key to skip"
	x=
	for i in 2 1 0; do
		read -N 1 -t 1 x
		echo "... $i"
		[ "$x" != '' ] && break
	done
	if [ "$x" = '' ]; then
		if [ "$cgroup" = 1 ]; then
			echo "INIT: enable cgroups"
			mkdir -p /sys/fs/cgroup/foo
			echo $$ > /sys/fs/cgroup/foo/cgroup.procs
			echo +io +memory > /sys/fs/cgroup/foo/cgroup.contollers
		fi

		echo "INIT: start autorun"
		/autorun.sh
		echo "INIT: autorun finished, back to shell"
	else
		echo "INIT: autorun skipped"
	fi
fi

echo "Init shell, exec /bin/bash"
resize
/bin/bash

#killall agetty
#wait

echo s > /proc/sysrq-trigger
echo u > /proc/sysrq-trigger
echo o > /proc/sysrq-trigger
