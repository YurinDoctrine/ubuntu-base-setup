#!/usr/bin/env bash
# Before hop in
sudo apt update &&
    DEBIAN_PRIORITY=critical sudo apt install -f --assume-yes base-files binutils fwupd git gnupg haveged kmod libc-bin libelf-dev libfaudio-dev libglvnd-dev libinput-dev libx11-dev lm-sensors lz4 libpci-dev pkgconf psmisc rtkit ufw upower va-driver-all wget xdg-utils xserver-xorg-video-vesa &&
    DEBIAN_PRIORITY=critical sudo apt install -f --assume-yes software-properties-common &&
    DEBIAN_PRIORITY=critical sudo apt install -f --assume-yes ubuntu-drivers-common ubuntu-restricted-addons ubuntu-restricted-extras

# ------------------------------------------------------------------------

echo -e "path-exclude /usr/share/doc/*
path-exclude /usr/share/help/*
path-exclude /usr/share/man/*
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
path-exclude /usr/share/locale/*
path-exclude /usr/share/gnome/help/*/*
path-exclude /usr/share/doc/kde/HTML/*/*
path-exclude /usr/share/omf/*/*-*.emf
# lintian stuff is small, but really unnecessary
path-exclude /usr/share/lintian/*
path-exclude /usr/share/linda/*
# paths to keep
path-include /usr/share/locale/locale.alias
path-include /usr/share/locale/en/*
path-include /usr/share/locale/en_GB/*
path-include /usr/share/locale/en_GB.UTF-8/*
# we need to keep copyright files for legal reasons
path-include /usr/share/doc/*/copyright" | sudo tee /etc/dpkg/dpkg.cfg.d/01_nodoc
echo -e 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/90nolanguages
# Compress indexes
echo -e 'Acquire::CompressionTypes::lz4 "lz4";' | sudo tee /etc/apt/apt.conf.d/02compress-indexes
# Disable APT terminal logging
echo -e 'Dir::Log::Terminal "";' | sudo tee /etc/apt/apt.conf.d/01disable-log
# Disable APT timers
sudo systemctl mask apt-daily.service >/dev/null 2>&1
sudo systemctl mask apt-daily-upgrade.service >/dev/null 2>&1
sudo systemctl mask apt-daily.timer >/dev/null 2>&1
sudo systemctl mask apt-daily-upgrade.timer >/dev/null 2>&1

# ------------------------------------------------------------------------

# Setting up locales & timezones
echo -e "LANG=en_GB.UTF8" | sudo tee -a /etc/environment
echo -e "LANGUAGE=en_GB.UTF8" | sudo tee -a /etc/environment
echo -e "LC_ALL=en_GB.UTF8" | sudo tee -a /etc/environment
echo -e "LC_COLLATE=C" | sudo tee -a /etc/environment
sudo apt install --reinstall --purge -yy locales
sudo sed -i -e 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen en_GB.UTF-8
sudo localectl set-locale LANG=en_GB.UTF-8
sudo timedatectl set-timezone Europe/Moscow
# Disable time sync service
sudo systemctl mask time-sync.target >/dev/null 2>&1

# ------------------------------------------------------------------------

# Don't reserve space man-pages, locales, licenses.
echo -e "Remove useless companies"
sudo apt-get remove --purge *texlive* -yy
find /usr/share/doc/ -depth -type f ! -name copyright | xargs sudo rm -f || true
find /usr/share/doc/ | grep '\.gz' | xargs sudo rm -f
find /usr/share/doc/ | grep '\.pdf' | xargs sudo rm -f
find /usr/share/doc/ | grep '\.tex' | xargs sudo rm -f
find /usr/share/doc/ -empty | xargs sudo rmdir || true
sudo rm -rfd /usr/share/groff/* /usr/share/info/* /usr/share/lintian/* \
    /usr/share/linda/* /var/cache/man/* /usr/share/man/* /usr/share/X11/locale/!\(en_GB\)
sudo rm -rfd /usr/share/locale/!\(en_GB\)

# ------------------------------------------------------------------------

# GNOME tweaks
sudo rm -rfd /etc/gdm{3}/custom.conf
sudo rm -rfd /etc/dconf/db/gdm{3}.d/01-logo
sudo rm -rfd /var/lib/gdm{3}/.cache/*

# Privacy
gsettings set org.gnome.system.location enabled false
gsettings set org.gnome.desktop.privacy disable-camera true
gsettings set org.gnome.desktop.privacy disable-microphone true
gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.desktop.privacy hide-identity true
gsettings set org.gnome.desktop.privacy report-technical-problems false
gsettings set org.gnome.desktop.privacy send-software-usage-stats false

# Security
gsettings set org.gnome.login-screen allowed-failures 100
gsettings set org.gnome.desktop.screensaver user-switch-enabled false
gsettings set org.gnome.SessionManager logout-prompt false
gsettings set org.gnome.desktop.media-handling autorun-never true

# Media
gsettings set org.gnome.desktop.sound event-sounds false
gsettings set org.gnome.settings-daemon.plugins.media-keys max-screencast-length 0

# Power
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive'
gsettings set org.gnome.desktop.interface enable-animations false

# Display
gsettings set org.gnome.desktop.interface scaling-factor 1
gsettings set org.gnome.desktop.interface text-scaling-factor 1.2
gsettings set org.gnome.mutter experimental-features "['x11-randr-fractional-scaling'"', '"'scale-monitor-framebuffer']"
gsettings set org.gnome.settings-daemon.plugins.xsettings antialiasing 'rgba'
gsettings set org.gnome.settings-daemon.plugins.xsettings hinting 'slight'

# Keyboard
gsettings set org.gnome.desktop.peripherals.keyboard delay 500
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 100

# Mouse
gsettings set org.gnome.desktop.peripherals.mouse accel-profile flat

# Misc
gsettings set org.gtk.Settings.FileChooser show-hidden true
gsettings set org.gnome.mutter attach-modal-dialogs false
gsettings set org.gnome.shell.overrides attach-modal-dialogs false
gsettings set org.gnome.shell.overrides edge-tiling true
gsettings set org.gnome.mutter edge-tiling true
gsettings set org.gnome.desktop.background color-shading-type vertical

# ------------------------------------------------------------------------

# KDE tweaks
kwriteconfig5 --file kwinrc --group Compositing --key "Enabled" --type bool true
kwriteconfig5 --file kwinrc --group Compositing --key "LatencyPolicy" "ExtremelyLow"
kwriteconfig5 --file kwinrc --group Compositing --key "AnimationSpeed" 3
kwriteconfig5 --file kwinrc --group Windows --key "AutoRaiseInterval" 125
kwriteconfig5 --file kwinrc --group Windows --key "DelayFocusInterval" 125
kwriteconfig5 --file kdeglobals --group KDE --key "AnimationDurationFactor" 0.125
kwriteconfig5 --file ksplashrc --group KSplash --key Engine "none"
kwriteconfig5 --file ksplashrc --group KSplash --key Theme "none"
kwriteconfig5 --file klaunchrc --group FeedbackStyle --key "BusyCursor" --type bool false
kwriteconfig5 --file klaunchrc --group BusyCursorSettings --key "Blinking" --type bool false
kwriteconfig5 --file klaunchrc --group BusyCursorSettings --key "Bouncing" --type bool false
kwriteconfig5 --file kwalletrc --group Wallet --key "Enabled" --type bool false
kwriteconfig5 --file kwalletrc --group Wallet --key "First Use" --type bool false

# ------------------------------------------------------------------------

# Set environment variables
echo -e "CPU_LIMIT=0
SHARED_MEMORY=1
MALLOC_CONF=background_thread:true
MALLOC_CHECK=0
MALLOC_TRACE=0
LD_DEBUG_OUTPUT=0
MESA_DEBUG=0
LIBGL_DEBUG=0
LIBGL_NO_DRAWARRAYS=1
LIBGL_THROTTLE_REFRESH=1
LIBC_FORCE_NOCHECK=1
HISTCONTROL=ignoreboth:eraseboth
HISTSIZE=5
LESSHISTFILE=-
LESSHISTSIZE=0
LESSSECURE=1
PAGER=less" | sudo tee -a /etc/environment

# ------------------------------------------------------------------------

# This may take time
echo -e "Installing Base System"

PKGS=(
    # --- Importants

    'chrony'      # Versatile implementation of the Network Time Protocol
    'dbus-broker' # Linux D-Bus Message Broker
    'mksh'        # MirBSD Korn Shell
    'powertop'    # A tool to diagnose issues with power consumption and power management
    'prelink'     # Makes applications run faster by prefetching ELF shared libraries and executables
    'preload'     # Makes applications run faster by prefetching binaries and shared objects
    'tumbler'     # D-Bus service for applications to request thumbnails

    # GENERAL UTILITIES ---------------------------------------------------

    'acpid'                  # A daemon for delivering ACPI power management events with netlink support
    'ethtool'                # An utility for controlling network drivers and hardware
    'irqbalance'             # IRQ balancing daemon for SMP systems
    'linux-cpupower'         # A tool to examine and tune power saving related features of your processor
    'numad'                  # Simple NUMA policy support
    'unscd'                  # Micro Name Service Caching Daemon
    'upx-ucl'                # An advanced executable file compressor
    'woff2'                  # Web Open Font Format 2

    # DEVELOPMENT ---------------------------------------------------------
    'clang'          # C language family frontend for LLVM
    'linux-libc-dev' # Linux support headers for userspace development

)

for PKG in "${PKGS[@]}"; do
    echo -e "INSTALLING: ${PKG}"
    sudo apt install -f --assume-yes --install-recommends "$PKG"
done

echo -e "Done!"

# ------------------------------------------------------------------------

echo -e "FINAL SETUP AND CONFIGURATION"

# Sudo rights
echo -e "Add sudo rights"
sudo sed -i -e 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# ------------------------------------------------------------------------

echo -e "Display asterisks when sudo"
echo -e "Defaults        pwfeedback" | sudo tee -a /etc/sudoers

# ------------------------------------------------------------------------

echo -e "Disabling Pulse .esd_auth module"
sudo killall -9 pulseaudio
# Pulse audio loads the `esound-protocol` module, which best I can tell is rarely needed.
# That module creates a file called `.esd_auth` in the home directory which I'd prefer to not be there. So...
sudo sed -i -e 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa
# Disable Pulse bluetooth switch
sudo sed -i -e 's|load-module module-switch-on-connect|#load-module module-switch-on-connect|g' /etc/pulse/default.pa
# Restart PulseAudio.
sudo killall -HUP pulseaudio

# ------------------------------------------------------------------------

# Prevent stupid feedbacks et cetera
echo -e "blacklist pcspkr
blacklist snd_pcsp
blacklist lpc_ich
blacklist gpio-ich
blacklist iTCO_wdt
blacklist iTCO_vendor_support
blacklist joydev
blacklist mousedev
blacklist mac_hid
blacklist uvcvideo
blacklist parport_pc
blacklist parport
blacklist lp
blacklist ppdev
blacklist sunrpc
blacklist floppy
blacklist arkfb
blacklist aty128fb
blacklist atyfb
blacklist radeonfb
blacklist cirrusfb
blacklist cyber2000fb
blacklist kyrofb
blacklist matroxfb_base
blacklist mb862xxfb
blacklist neofb
blacklist pm2fb
blacklist pm3fb
blacklist s3fb
blacklist savagefb
blacklist sisfb
blacklist tdfxfb
blacklist tridentfb
blacklist vt8623fb
blacklist sp5100-tco
blacklist sp5100_tco
blacklist pcmcia
blacklist yenta_socket
blacklist dccp
blacklist sctp
blacklist rds
blacklist tipc
blacklist n-hdlc
blacklist ax25
blacklist netrom
blacklist x25
blacklist rose
blacklist decnet
blacklist econet
blacklist af_802154
blacklist ipx
blacklist appletalk
blacklist psnap
blacklist p8022
blacklist p8023
blacklist llc
blacklist i2400m
blacklist i2400m_usb
blacklist wimax
blacklist parport
blacklist parport_pc
blacklist cramfs
blacklist freevxfs
blacklist jffs2
blacklist hfs
blacklist hfsplus
blacklist squashfs
blacklist udf
blacklist wl
blacklist ssb
blacklist b43
blacklist b43legacy
blacklist bcma
blacklist bcm43xx
blacklist brcm80211
blacklist brcmfmac
blacklist brcmsmac" | sudo tee /etc/modprobe.d/nomisc.conf
# Disable bios limit
echo -e "options processor ignore_ppc=1" | sudo tee /etc/modprobe.d/ignore_ppc.conf

# ------------------------------------------------------------------------

# Prevent motd news*
sudo sed -i -e 's/ENABLED=.*/ENABLED=0/' /etc/default/motd-news
sudo systemctl mask motd-news.timer >/dev/null 2>&1

# ------------------------------------------------------------------------

# btrfs tweaks if disk is
sudo systemctl enable btrfs-scrub@home.timer
sudo systemctl enable btrfs-scrub@-.timer
sudo btrfs property set / compression lz4
sudo btrfs property set /home compression lz4
sudo btrfs filesystem defragment -r -v -clz4 /
sudo chattr +c /
sudo btrfs filesystem defragment -r -v -clz4 /home
sudo chattr +c /home
sudo btrfs balance start -musage=0 -dusage=50 /
sudo btrfs balance start -musage=0 -dusage=50 /home
sudo chattr +C /swapfile

# ------------------------------------------------------------------------

echo -e "Apply disk tweaks"
sudo sed -i -e 's| defaults| rw,lazytime,relatime,commit=3600,delalloc,nobarrier,nofail,discard|g' /etc/fstab
sudo sed -i -e 's| errors=remount-ro| rw,lazytime,relatime,commit=3600,delalloc,nobarrier,nofail,discard,errors=remount-ro|g' /etc/fstab

# ------------------------------------------------------------------------

# Optimize sysctl
sudo sed -i -e '/^\/\/swappiness/d' /etc/sysctl.conf
echo -e "vm.swappiness = 1
vm.vfs_cache_pressure = 50
vm.overcommit_memory = 1
vm.overcommit_ratio = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 20
vm.stat_interval = 60
vm.page-cluster = 0
vm.dirty_expire_centisecs = 500
vm.oom_dump_tasks = 1
vm.oom_kill_allocating_task = 1
vm.extfrag_threshold = 750
vm.block_dump = 0
vm.reap_mem_on_sigkill = 1
vm.panic_on_oom = 0
vm.zone_reclaim_mode = 0
vm.scan_unevictable_pages = 0
vm.compact_unevictable_allowed = 1
vm.compaction_proactiveness = 0
vm.page_lock_unfairness = 1
vm.percpu_pagelist_high_fraction = 0
vm.pagecache = 1
vm.watermark_scale_factor = 1
vm.memory_failure_recovery = 0
vm.max_map_count = 262144
min_perf_pct = 100
kernel.io_delay_type = 3
kernel.task_delayacct = 0
kernel.sysrq = 0
kernel.watchdog_thresh = 60
kernel.nmi_watchdog = 0
kernel.seccomp = 0
kernel.timer_migration = 0
kernel.core_pipe_limit = 0
kernel.core_uses_pid = 1
kernel.hung_task_timeout_secs = 0
kernel.sched_rr_timeslice_ms = -1
kernel.sched_rt_runtime_us = -1
kernel.sched_rt_period_us = 1
kernel.sched_child_runs_first = 1
kernel.sched_tunable_scaling = 1
kernel.sched_schedstats = 0
kernel.sched_energy_aware = 0
kernel.sched_autogroup_enabled = 0
kernel.sched_compat_yield = 0
kernel.sched_min_task_util_for_colocation = 0
kernel.sched_nr_migrate = 4
kernel.sched_migration_cost_ns = 250000
kernel.sched_latency_ns = 400000
kernel.sched_min_granularity_ns = 400000
kernel.sched_wakeup_granularity_ns = 500000
kernel.sched_scaling_enable = 1
kernel.sched_itmt_enabled = 1
kernel.numa_balancing = 1
kernel.panic = 0
kernel.panic_on_oops = 0
kernel.perf_cpu_time_max_percent = 1
kernel.printk_devkmsg = off
kernel.compat-log = 0
kernel.yama.ptrace_scope = 1
kernel.stack_tracer_enabled = 0
kernel.random.urandom_min_reseed_secs = 120
kernel.perf_event_paranoid = -1
kernel.perf_event_max_contexts_per_stack = 2
kernel.perf_event_max_sample_rate = 1
kernel.kptr_restrict = 0
kernel.randomize_va_space = 0
kernel.exec-shield = 0
kernel.kexec_load_disabled = 1
kernel.acpi_video_flags = 0
kernel.unknown_nmi_panic = 0
kernel.panic_on_unrecovered_nmi = 0
dev.i915.perf_stream_paranoid = 0
dev.scsi.logging_level = 0
debug.exception-trace = 0
debug.kprobes-optimization = 1
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 1048576
fs.inotify.max_queued_events = 1048576
fs.quota.allocated_dquots = 0
fs.quota.cache_hits = 0
fs.quota.drops = 0
fs.quota.free_dquots = 0
fs.quota.lookups = 0
fs.quota.reads = 0
fs.quota.syncs = 0
fs.quota.warnings = 0
fs.quota.writes = 0
fs.leases-enable = 1
fs.lease-break-time = 5
fs.dir-notify-enable = 0
force_latency = 1
net.ipv4.tcp_frto=1
net.ipv4.tcp_frto_response=2
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_ecn=1
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_early_retrans=2
net.ipv4.tcp_thin_dupack=1
net.ipv4.tcp_autocorking=0
net.ipv4.tcp_reordering=3
net.ipv4.tcp_timestamps=0
net.core.bpf_jit_enable=1
net.core.bpf_jit_harden=0
net.core.bpf_jit_kallsyms=0" | sudo tee /etc/sysctl.d/99-swappiness.conf
echo -e "Drop caches"
sudo sysctl -w vm.compact_memory=1 && sudo sysctl -w vm.drop_caches=3 && sudo sysctl -w vm.drop_caches=2
echo -e "Restart swap"
sudo swapoff -av && sudo swapon -av

# ------------------------------------------------------------------------

# Enable trim
sudo systemctl enable fstrim.service
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.service
sudo systemctl start fstrim.timer
echo -e "Run fstrim"
sudo fstrim -Av

# ------------------------------------------------------------------------

## Remove floppy cdrom
sudo sed -i -e '/floppy/d' /etc/fstab
sudo sed -i -e '/sr/d' /etc/fstab

# ------------------------------------------------------------------------

## DPKG keep current versions of configs
echo -e 'DPkg::Options {
   "--force-confdef";
};' | sudo tee /etc/apt/apt.conf.d/71debconf
## APT no install suggests
echo -e 'APT::Get::Install-Suggests "false";' | sudo tee /etc/apt/apt.conf.d/95nosuggests
## Disable APT caches
echo -e 'Dir::Cache {
   archives "";
   srcpkgcache "";
   pkgcache "";
};' | sudo tee /etc/apt/apt.conf.d/02nocache

# ------------------------------------------------------------------------

## Set some ulimits to unlimited
echo -e "* soft nofile 524288
* hard nofile 524288
root soft nofile 524288
root hard nofile 524288
* soft as unlimited
* hard as unlimited
root soft as unlimited
root hard as unlimited
* soft memlock unlimited
* hard memlock unlimited
root soft memlock unlimited
root hard memlock unlimited
* soft core unlimited
* hard core unlimited
root soft core unlimited
root hard core unlimited
* soft nproc unlimited
* hard nproc unlimited
root soft nproc unlimited
root hard nproc unlimited
* soft sigpending unlimited
* hard sigpending unlimited
root soft sigpending unlimited
root hard sigpending unlimited
* soft stack unlimited
* hard stack unlimited
root soft stack unlimited
root hard stack unlimited
* soft data unlimited
* hard data unlimited
root soft data unlimited
root hard data unlimited" | sudo tee /etc/security/limits.conf
## Set realtime to unlimited
echo -e "@realtime - rtprio 99
@realtime - memlock unlimited" | sudo tee -a /etc/security/limits.conf

# ------------------------------------------------------------------------

echo -e "Disable wait online service"
echo -e "[connectivity]
enabled=false" | sudo tee /etc/NetworkManager/conf.d/20-connectivity.conf
sudo systemctl mask NetworkManager-wait-online.service >/dev/null 2>&1

# ------------------------------------------------------------------------

echo -e "Disable SELINUX"
echo -e "SELINUX=disabled
SELINUXTYPE=minimum" | sudo tee /etc/selinux/config
sudo setenforce 0

# ------------------------------------------------------------------------

## Don't autostart .desktop
sudo sed -i -e 's/NoDisplay=true/NoDisplay=false/g' /etc/xdg/autostart/*.desktop

# ------------------------------------------------------------------------

echo -e "Enable tmpfs ramdisk"
sudo sed -i -e '/^\/\/tmpfs/d' /etc/fstab
echo -e "tmpfs /var/tmp tmpfs nodiratime,nodev,nosuid,mode=1777,size=300m 0 0
tmpfs /var/log tmpfs nodiratime,nodev,nosuid,mode=1777,size=300m 0 0
tmpfs /var/run tmpfs nodiratime,nodev,nosuid,mode=1777,size=300m 0 0
tmpfs /var/lock tmpfs nodiratime,nodev,nosuid,mode=1777,size=300m 0 0
tmpfs /var/cache tmpfs nodiratime,nodev,nosuid,mode=1777,size=300m 0 0
tmpfs /var/volatile tmpfs nodiratime,nodev,nosuid,mode=1777,size=300m 0 0
tmpfs /var/spool tmpfs nodiratime,nodev,nosuid,mode=1777,size=300m 0 0
tmpfs /media tmpfs nodiratime,nodev,nosuid,mode=1777,size=300m 0 0
tmpfs /dev/shm tmpfs nodiratime,nodev,nosuid,mode=1777,size=300m 0 0" | sudo tee -a /etc/fstab

# ------------------------------------------------------------------------

## Disable resume from hibernate
echo -e "#" | sudo tee /etc/initramfs-tools/conf.d/resume
echo -e "Disable hibernate/hybrid-sleep service"
sudo systemctl mask hibernate.target hybrid-sleep.target

# ------------------------------------------------------------------------

echo -e "Enable dbus-broker"
sudo systemctl enable dbus-broker.service
sudo systemctl --global enable dbus-broker.service

# ------------------------------------------------------------------------

echo -e "Disable systemd-timesync daemon"
sudo systemctl disable systemd-timesyncd.service
sudo systemctl --global disable systemd-timesyncd.service

# ------------------------------------------------------------------------

echo -e "Optimize writes to the disk"
sudo sed -i -e s"/\#Storage=.*/Storage=none/"g /etc/systemd/coredump.conf
sudo sed -i -e s"/\#Seal=.*/Seal=no/"g /etc/systemd/coredump.conf
sudo sed -i -e s"/\#Storage=.*/Storage=none/"g /etc/systemd/journald.conf
sudo sed -i -e s"/\#Seal=.*/Seal=no/"g /etc/systemd/journald.conf

# ------------------------------------------------------------------------

## Enable ALPM
if [[ -e /etc/pm/config.d ]]; then
    echo -e "SATA_ALPM_ENABLE=true
SATA_LINKPWR_ON_BAT=min_power" | sudo tee /etc/pm/config.d/sata_alpm
else
    sudo mkdir /etc/pm/config.d
    echo -e "SATA_ALPM_ENABLE=true
SATA_LINKPWR_ON_BAT=min_power" | sudo tee /etc/pm/config.d/sata_alpm
fi

# ------------------------------------------------------------------------

echo -e "Enable NetworkManager powersave on"
echo -e "[connection]
wifi.powersave = 1" | sudo tee /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf

# ------------------------------------------------------------------------

## Suspend when lid is closed
sudo sed -i -e 's/#HandleLidSwitch=.*/HandleLidSwitch=suspend/' /etc/systemd/logind.conf
sudo sed -i -e 's/#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=suspend/' /etc/systemd/logind.conf
sudo sed -i -e 's/#HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf
## Reboot when long press power key
sudo sed -i -e 's/#HandlePowerKeyLongPress=.*/HandlePowerKeyLongPress=reboot/' /etc/systemd/logind.conf

# ------------------------------------------------------------------------

echo -e "Disable bluetooth autostart"
sudo sed -i -e 's/AutoEnable.*/AutoEnable = false/' /etc/bluetooth/main.conf
sudo sed -i -e 's/FastConnectable.*/FastConnectable = false/' /etc/bluetooth/main.conf
sudo sed -i -e 's/ReconnectAttempts.*/ReconnectAttempts = 1/' /etc/bluetooth/main.conf
sudo sed -i -e 's/ReconnectIntervals.*/ReconnectIntervals = 1/' /etc/bluetooth/main.conf

# ------------------------------------------------------------------------

echo -e "Disable systemd radio service/socket"
sudo systemctl disable systemd-rfkill.service
sudo systemctl --global disable systemd-rfkill.service
sudo systemctl disable systemd-rfkill.socket
sudo systemctl --global disable systemd-rfkill.socket
echo -e "Disable ModemManager"
sudo systemctl disable ModemManager
sudo systemctl --global disable ModemManager
echo -e "Disable speech-dispatcher"
sudo systemctl disable speech-dispatcher
sudo systemctl --global disable speech-dispatcher
echo -e "Disable smartmontools"
sudo systemctl disable smartmontools
sudo systemctl --global disable smartmontools
echo -e "Disable kerneloops"
sudo systemctl disable kerneloops.service
sudo systemctl --global disable kerneloops.service
echo -e "Disable whoopsie"
sudo systemctl disable whoopsie.service
sudo systemctl --global disable whoopsie.service
echo -e "Disable saned service/socket"
sudo systemctl disable saned.service
sudo systemctl --global disable saned.service
sudo systemctl disable saned.socket
sudo systemctl --global disable saned.socket
echo -e "Disable apport service/socket"
sudo systemctl disable apport.service
sudo systemctl --global disable apport.service
sudo systemctl disable apport-forward.socket
sudo systemctl --global disable apport-forward.socket
echo -e "Disable brltty"
sudo systemctl disable brltty.service
sudo systemctl --global disable brltty.service
sudo systemctl disable brltty-udev.service
sudo systemctl --global disable brltty-udev.service
echo -e "Disable man-db service/timer"
sudo systemctl disable man-db.service
sudo systemctl --global disable man-db.service
sudo systemctl disable man-db.timer
sudo systemctl --global disable man-db.timer

# ------------------------------------------------------------------------

## Fix connecting local devices
sudo sed -i -e 's/hosts: .*/hosts: files mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns mdns4 mdns/' /etc/nsswitch.conf

# ------------------------------------------------------------------------

echo -e "Reduce systemd timeout"
sudo sed -i -e 's/#DefaultTimeoutStartSec.*/DefaultTimeoutStartSec=5s/g' /etc/systemd/system.conf
sudo sed -i -e 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=5s/g' /etc/systemd/system.conf

# ------------------------------------------------------------------------

echo -e "Enable NetworkManager dispatcher"
sudo systemctl enable NetworkManager-dispatcher.service
sudo systemctl --global enable NetworkManager-dispatcher.service

# ------------------------------------------------------------------------

echo -e "Disable systemd avahi daemon service"
sudo systemctl disable avahi-daemon.service
sudo systemctl --global disable avahi-daemon.service

# ------------------------------------------------------------------------

## Set zram
sudo sed -i -e 's/#ALGO.*/ALGO=lz4/g' /etc/default/zramswap
sudo sed -i -e 's/PERCENT.*/PERCENT=25/g' /etc/default/zramswap

# ------------------------------------------------------------------------

## Flush bluetooth
sudo rm -rfd /var/lib/bluetooth/*

# ------------------------------------------------------------------------

echo -e "Disable plymouth"
sudo systemctl mask plymouth-read-write.service >/dev/null 2>&1
sudo systemctl mask plymouth-start.service >/dev/null 2>&1
sudo systemctl mask plymouth-quit.service >/dev/null 2>&1
sudo systemctl mask plymouth-quit-wait.service >/dev/null 2>&1

# ------------------------------------------------------------------------

echo -e "Disable remote-fs"
sudo systemctl mask remote-fs.target >/dev/null 2>&1

# ------------------------------------------------------------------------

## Some powersavings
echo "options vfio_pci disable_vga=1
options cec debug=0
options kvm mmu_audit=0
options kvm ignore_msrs=1
options kvm report_ignored_msrs=0
options kvm kvmclock_periodic_sync=1
options nfs enable_ino64=1
options pstore backend=null
options libata allow_tpm=0
options libata ignore_hpa=0
options libahci ignore_sss=1
options libahci skip_host_reset=1
options snd_hda_intel power_save=1
options snd_ac97_codec power_save=1
options uhci-hcd debug=0
options usbhid mousepoll=4
options usb-storage quirks=p
options usbcore usbfs_snoop=0
options usbcore autosuspend=5" | sudo tee /etc/modprobe.d/powersavings.conf
echo -e "min_power" | sudo tee /sys/class/scsi_host/*/link_power_management_policy
echo 1 | sudo tee /sys/module/snd_hda_intel/parameters/power_save
echo -e "auto" | sudo tee /sys/bus/{i2c,pci}/devices/*/power/control
sudo powertop --auto-tune && sudo powertop --auto-tune
sudo cpupower frequency-set -g powersave
sudo cpupower set --perf-bias 9
sudo sensors-detect --auto

# ------------------------------------------------------------------------

## Disable file indexer
balooctl suspend
balooctl disable
balooctl purge
sudo systemctl disable plasma-baloorunner
for dir in $HOME $HOME/*/; do touch "$dir/.metadata_never_index" "$dir/.noindex" "$dir/.nomedia" "$dir/.trackerignore"; done

# ------------------------------------------------------------------------

echo -e "Enable write cache"
echo -e "write back" | sudo tee /sys/block/*/queue/write_cache
sudo tune2fs -o journal_data_writeback $(df / | grep / | awk '{print $1}')
sudo tune2fs -O ^has_journal $(df / | grep / | awk '{print $1}')
sudo tune2fs -o journal_data_writeback $(df /home | grep /home | awk '{print $1}')
sudo tune2fs -O ^has_journal $(df /home | grep /home | awk '{print $1}')
echo -e "Enable fast commit"
sudo tune2fs -O fast_commit $(df / | grep / | awk '{print $1}')
sudo tune2fs -O fast_commit $(df /home | grep /home | awk '{print $1}')

# ------------------------------------------------------------------------

echo -e "Compress .local/bin"
upx /home/$USER/.local/bin/*

# ------------------------------------------------------------------------

echo -e "Improve I/O throughput"
echo 32 | sudo tee /sys/block/sd*[!0-9]/queue/iosched/fifo_batch
echo 32 | sudo tee /sys/block/mmcblk*/queue/iosched/fifo_batch
echo 32 | sudo tee /sys/block/nvme[0-9]*/queue/iosched/fifo_batch

# ------------------------------------------------------------------------

## Default target graphical user
sudo systemctl set-default graphical.target

# ------------------------------------------------------------------------

echo -e "Disable systemd foo service"
sudo systemctl disable foo.service
sudo systemctl --global disable foo.service

# ------------------------------------------------------------------------

## Improve wifi and ethernet
if ip -o link | grep -q wlan; then
    echo -e "options iwlwifi bt_coex_active=0 swcrypto=1 11n_disable=8
options iwlmvm power_scheme=0" | sudo tee /etc/modprobe.d/wlan.conf
    echo -e "options rfkill default_state=0 master_switch_mode=0" | sudo tee /etc/modprobe.d/wlanextra.conf
    sudo ethtool -K wlan0 gro on
    sudo ethtool -K wlan0 gso on
    sudo ethtool -c wlan0
    sudo iwconfig wlan0 txpower auto
    sudo iwpriv wlan0 set_power 5
else
    sudo ethtool -s eth0 wol d
    sudo ethtool -K eth0 gro off
    sudo ethtool -K eth0 gso off
    sudo ethtool -C eth0 adaptive-rx on
    sudo ethtool -C eth0 adaptive-tx on
    sudo ethtool -c eth0
fi

# ------------------------------------------------------------------------

echo -e "Enable HDD write caching"
sudo hdparm -A1 -W1 -B254 -S0 /dev/sd*[!0-9]

# ------------------------------------------------------------------------

echo -e "Enable compose cache on disk"
sudo mkdir -p /var/cache/libx11/compose
mkdir -p /home/$USER/.compose-cache
touch /home/$USER/.XCompose

# ------------------------------------------------------------------------

## Improve NVME
if $(find /sys/block/nvme[0-9]* | grep -q nvme); then
    echo -e "options nvme_core default_ps_max_latency_us=0" | sudo tee /etc/modprobe.d/nvme.conf
fi

# ------------------------------------------------------------------------

## Improve PCI latency
sudo setpci -v -d *:* latency_timer=48 >/dev/null 2>&1

# ------------------------------------------------------------------------

## Improve preload
sudo sed -i -e 's/sortstrategy =.*/sortstrategy = 0/' /etc/preload.conf

# ------------------------------------------------------------------------

echo -e "Disable fsck"
sudo tune2fs -c 0 -i 0 $(df / | grep / | awk '{print $1}')
sudo tune2fs -c 0 -i 0 $(df /home | grep /home | awk '{print $1}')
echo -e "Disable checksum"
sudo tune2fs -O ^metadata_csum $(df / | grep / | awk '{print $1}')
sudo tune2fs -O ^metadata_csum $(df /home | grep /home | awk '{print $1}')
echo -e "Disable quota"
sudo tune2fs -O ^quota $(df / | grep / | awk '{print $1}')
sudo tune2fs -O ^quota $(df /home | grep /home | awk '{print $1}')

# ------------------------------------------------------------------------

echo -e "Disable logging services"
sudo systemctl mask dev-mqueue.mount >/dev/null 2>&1
sudo systemctl mask sys-kernel-tracing.mount >/dev/null 2>&1
sudo systemctl mask sys-kernel-debug.mount >/dev/null 2>&1
sudo systemctl mask sys-kernel-config.mount >/dev/null 2>&1
sudo systemctl mask systemd-update-utmp.service >/dev/null 2>&1
sudo systemctl mask systemd-update-utmp-runlevel.service >/dev/null 2>&1
sudo systemctl mask systemd-update-utmp-shutdown.service >/dev/null 2>&1
sudo systemctl mask systemd-journal-flush.service >/dev/null 2>&1
sudo systemctl mask systemd-journal-catalog-update.service >/dev/null 2>&1
sudo systemctl mask systemd-journald-dev-log.socket >/dev/null 2>&1
sudo systemctl mask systemd-journald-audit.socket >/dev/null 2>&1
sudo systemctl mask logrotate.service >/dev/null 2>&1
sudo systemctl mask logrotate.timer >/dev/null 2>&1
sudo systemctl mask syslog.service >/dev/null 2>&1
sudo systemctl mask syslog.socket >/dev/null 2>&1
sudo systemctl mask rsyslog.service >/dev/null 2>&1

# ------------------------------------------------------------------------

## GRUB timeout
sudo sed -i -e 's/GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub
sudo sed -i -e 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
sudo sed -i -e 's/GRUB_RECORDFAIL_TIMEOUT=.*/GRUB_RECORDFAIL_TIMEOUT=0/' /etc/default/grub
## Change GRUB defaults
sudo sed -i -e 's/GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=true/' /etc/default/grub
sudo sed -i -e 's/GRUB_DISABLE_RECOVERY=.*/GRUB_DISABLE_RECOVERY=true/' /etc/default/grub
sudo sed -i -e 's/GRUB_DISABLE_SUBMENU=.*/GRUB_DISABLE_SUBMENU=true/' /etc/default/grub
sudo sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet rootfstype=ext4,btrfs,xfs,f2fs biosdevname=0 nowatchdog noautogroup noresume default_hugepagesz=2M hugepagesz=2M hugepages=256 zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=10 zswap.zpool=zsmalloc workqueue.power_efficient=1 pcie_aspm=force pci=pcie_bus_perf,noaer rd.plymouth=0 plymouth.enable=0 plymouth.ignore-serial-consoles logo.nologo consoleblank=0 vt.global_cursor_default=0 rd.systemd.show_status=auto loglevel=0 rd.udev.log_level=0 udev.log_priority=0 enable_hangcheck=0 error_capture=0 msr.allow_writes=on audit=0 nosoftlockup selinux=0 enforcing=0 mce=0 mds=full,nosmt vsyscall=none no_timer_check skew_tick=1 clocksource=tsc tsc=perfect nohz=on rcupdate.rcu_expedited=1 rcu_nocb_poll irqpoll threadirqs irqaffinity=0 noirqdebug iomem=relaxed kthread_cpus=0 sched_policy=1 idle=nomwait noreplace-smp noatime boot_delay=0 io_delay=none rootdelay=0 elevator=noop realloc init_on_alloc=0 init_on_free=0 pti=on no_stf_barrier mitigations=off ftrace_enabled=0 fsck.repair=no fsck.mode=skip cryptomgr.notests"/' /etc/default/grub
sudo update-grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
echo -e "Disable GPU polling"
echo -e "options drm_kms_helper poll=0" | sudo tee /etc/modprobe.d/disable-gpu-polling.conf
echo -e "Enable BFQ scheduler"
echo -e "bfq" | sudo tee /etc/modules-load.d/bfq.conf
echo -e 'ACTION=="add|change", ATTR{queue/scheduler}=="*bfq*", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/scheduler}="bfq"' | sudo tee /etc/udev/rules.d/60-scheduler.rules
echo -e 'ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/iosched/slice_idle}="0", ATTR{queue/iosched/low_latency}="1"' | sudo tee /etc/udev/rules.d/90-low-latency.rules
## Enable lz4 compression
sudo sed -i -e 's/MODULES=most/MODULES=dep/g' /etc/initramfs-tools/initramfs.conf
sudo sed -i -e 's/COMPRESS=.*/COMPRESS=lz4/g' /etc/initramfs-tools/initramfs.conf
sudo update-initramfs -u -k all
sudo mkinitramfs -c lz4 -o /boot/initrd.img-*

# ------------------------------------------------------------------------

extra() {
    cd /tmp
    curl --tlsv1.2 -fsSL https://raw.githubusercontent.com/YurinDoctrine/ultra-gaming-setup-wizard/main/ultra-gaming-setup-wizard.sh >ultra-gaming-setup-wizard.sh &&
        chmod 0755 ultra-gaming-setup-wizard.sh &&
        ./ultra-gaming-setup-wizard.sh
}

extra2() {
    cd /tmp
    curl --tlsv1.2 -fsSL https://raw.githubusercontent.com/YurinDoctrine/secure-linux/master/secure.sh >secure.sh &&
        chmod 0755 secure.sh &&
        ./secure.sh
}

final() {
    sleep 1s
    clear
    echo -e "
###############################################################################
# All Done! Would you also mind to run the author's ultra-gaming-setup-wizard?
###############################################################################
"

    read -p $'yes/no >_: ' ans
    if [[ "$ans" == "yes" ]]; then
        echo -e "RUNNING ..."
        sudo ln -sfT mksh /usr/bin/sh # Link mksh to /usr/bin/sh
        extra
    elif [[ "$ans" == "no" ]]; then
        echo -e "LEAVING ..."
        echo -e ""
        echo -e "FINAL: DO YOU ALSO WANT TO RUN THE AUTHOR'S secure-linux?"
        read -p $'yes/no >_: ' noc
        if [[ "$noc" == "yes" ]]; then
            echo -e "RUNNING ..."
            sudo ln -sfT mksh /usr/bin/sh # Link mksh to /usr/bin/sh
            extra2
        elif [[ "$noc" == "no" ]]; then
            echo -e "LEAVING ..."
            sudo ln -sfT mksh /usr/bin/sh # Link mksh to /usr/bin/sh
            return 0
        else
            echo -e "INVALID VALUE!"
            final
        fi
    else
        echo -e "INVALID VALUE!"
        final
    fi
}
final
cd

# ------------------------------------------------------------------------

echo -e "Purge snapd garbage"
sudo systemctl mask snapd >/dev/null 2>&1
sudo systemctl mask snapd.service >/dev/null 2>&1
sudo systemctl mask snapd.socket >/dev/null 2>&1
sudo systemctl mask snapd.seeded.service >/dev/null 2>&1
sudo systemctl mask snapd.autoimport.service >/dev/null 2>&1
sudo systemctl mask snapd.apparmor.service >/dev/null 2>&1
sudo rm -rfd /etc/apparmor.d/usr.lib.snapd.snap-confine.real
sudo umount /run/snap/ns
sudo snap remove $(snap list | awk '!/^Name|^bare|^core|^snapd/ {print $1}')
sudo apt-get remove -yy --purge snapd *-snap
sudo apt-mark hold snapd
sudo rm -rfd /home/$USER/snap
sudo rm -rfd /snap
sudo rm -rfd /var/snap
sudo rm -rfd /var/lib/snapd
sudo rm -rfd /var/cache/snapd
sudo rm -rfd /usr/lib/snapd
echo -e "Flush flatpak database"
sudo flatpak uninstall --unused --delete-data -y
sudo flatpak repair
echo -e "Clear the caches"
for n in $(find / -type d \( -name ".tmp" -o -name ".temp" -o -name ".cache" \) 2>/dev/null); do sudo find "$n" -type f -delete; done
echo -e "Clear the patches"
rm -rfd /{tmp,var/tmp}/{.*,*}
sudo rm -rfd /var/cache/apt/archives/*
sudo rm -rfd /var/lib/dpkg/info/*.postinst
sudo dpkg --configure -a
sudo apt-get remove -yy --purge --ignore-missing $(/bin/dpkg -l | /bin/grep "^rc" | /bin/awk '{print $2}')
sudo apt-get autoremove -yy --purge --ignore-missing
sudo apt-get clean -y
sudo apt-get autoclean -y
sudo apt-get install -f --assume-yes

# ------------------------------------------------------------------------

echo -e "Compress fonts"
woff2_compress /usr/share/fonts/opentype/*/*ttf
woff2_compress /usr/share/fonts/truetype/*/*ttf
## Optimize font cache
fc-cache -rfv
## Optimize icon cache
gtk-update-icon-cache

# ------------------------------------------------------------------------

echo -e "Clean crash log"
sudo rm -rfd /var/crash/*
echo -e "Clean archived journal"
sudo journalctl --rotate --vacuum-time=0.1
sudo sed -i -e 's/^#ForwardToSyslog=yes/ForwardToSyslog=no/' /etc/systemd/journald.conf
sudo sed -i -e 's/^#ForwardToKMsg=yes/ForwardToKMsg=no/' /etc/systemd/journald.conf
sudo sed -i -e 's/^#ForwardToConsole=yes/ForwardToConsole=no/' /etc/systemd/journald.conf
sudo sed -i -e 's/^#ForwardToWall=yes/ForwardToWall=no/' /etc/systemd/journald.conf
echo -e "Compress log files"
sudo sed -i -e 's/^#Compress=yes/Compress=yes/' /etc/systemd/journald.conf
sudo sed -i -e 's/^#compress/compress/' /etc/logrotate.conf
echo -e "Scrub free space and sync"
echo -e "kernel.core_pattern=/dev/null" | sudo tee /etc/sysctl.d/50-coredump.conf
sudo dd bs=4k if=/dev/null of=/var/tmp/dummy || sudo rm -rfd /var/tmp/dummy
sync -f
