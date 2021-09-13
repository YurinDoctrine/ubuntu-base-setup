#!/usr/bin/env bash
# Before hop in
sudo apt update &&
    sudo apt install -f --assume-yes 9base curl git psmisc software-properties-common ufw wget &&
    sudo apt install -f --assume-yes ubuntu-drivers-common &&
    sudo apt install -f --assume-yes --no-install-recommends kubuntu-restricted-extras kubuntu-restricted-addons

# ------------------------------------------------------------------------

echo -e "# we need to keep copyright files for legal reasons
path-include /usr/share/doc/*/copyright
path-exclude /usr/share/doc/*
path-exclude /usr/share/man/*
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
# lintian stuff is small, but really unnecessary
path-exclude /usr/share/lintian/*
path-exclude /usr/share/linda/*" | sudo tee /etc/dpkg/dpkg.cfg.d/01_nodoc
echo -e 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/90nolanguages

# ------------------------------------------------------------------------

# Setting up locales & timezones
echo -e "LANG=en_GB.UTF8" | sudo tee -a /etc/environment
echo -e "LANGUAGE=en_GB.UTF8" | sudo tee -a /etc/environment
echo -e "LC_ALL=en_GB.UTF8" | sudo tee -a /etc/environment
sudo apt install --reinstall --purge -y locales
sudo sed -i -e 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen en_GB.UTF-8
sudo timedatectl set-ntp true
sudo timedatectl set-timezone Europe/Moscow

# ------------------------------------------------------------------------

# Don't reserve space man-pages, locales, licenses.
echo -e "Remove useless companies"
sudo apt-get remove --purge \
    texlive-fonts-recommended-doc texlive-latex-base-doc texlive-latex-extra-doc \
    texlive-latex-recommended-doc texlive-pictures-doc texlive-pstricks-doc
find /usr/share/doc/ -depth -type f ! -name copyright | xargs sudo rm -f || true
find /usr/share/doc/ | egrep '\.gz' | xargs sudo rm -f
find /usr/share/doc/ | egrep '\.pdf' | xargs sudo rm -f
find /usr/share/doc/ | egrep '\.tex' | xargs sudo rm -f
find /usr/share/doc/ -empty | xargs sudo rmdir || true
sudo rm -rfd /usr/share/groff/* /usr/share/info/* /usr/share/lintian/* \
    /usr/share/linda/* /var/cache/man/* /usr/share/man/*

# ------------------------------------------------------------------------

# This may take time
echo -e "Installing Base System"

PKGS=(
    # --- Importants

    'mksh' # MirBSD Korn Shell

    # GENERAL UTILITIES ---------------------------------------------------

    'irqbalance' # IRQ balancing daemon for SMP systems
    'powertop'   # A tool to diagnose issues with power consumption and power management
    'preload'    # Makes applications run faster by prefetching binaries and shared objects

)

for PKG in "${PKGS[@]}"; do
    echo -e "INSTALLING: ${PKG}"
    sudo apt install -f --assume-yes --no-install-recommends "$PKG"
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

echo -e "Configuring vconsole.conf to set a larger font for login shell"
echo -e "FONT=ter-v32b" | sudo tee /etc/vconsole.conf

# ------------------------------------------------------------------------

echo -e "Disabling Pulse .esd_auth module"
sudo killall -9 pulseaudio
# Pulse audio loads the `esound-protocol` module, which best I can tell is rarely needed.
# That module creates a file called `.esd_auth` in the home directory which I'd prefer to not be there. So...
sudo sed -i -e 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa
# Restart PulseAudio.
sudo killall -HUP pulseaudio

# ------------------------------------------------------------------------

# Prevent stupid error beeps*
sudo rmmod pcspkr
echo -e "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

# ------------------------------------------------------------------------

# Prevent motd news*
sudo sed -i -e 's/ENABLED=.*/ENABLED=0/' /etc/default/motd-news
sudo systemctl mask motd-news.timer

# ------------------------------------------------------------------------

# btrfs tweaks if disk is
sudo btrfs balance start -musage=50 -dusage=50 /

# ------------------------------------------------------------------------

echo -e "Apply disk tweaks"
sudo sed -i -e 's| defaults | noatime,nodiratime,commit=60 |g' /etc/fstab
sudo sed -i -e 's| errors=remount-ro 0 | noatime,nodiratime,commit=60,errors=remount-ro 0 |g' /etc/fstab

# ------------------------------------------------------------------------

# Optimize sysctl
sudo sed -i -e '/^\/\/swappiness/d' /etc/sysctl.conf
echo -e "vm.swappiness=1
vm.vfs_cache_pressure=50
vm.mmap_min_addr = 4096
vm.overcommit_memory = 2
vm.overcommit_ratio = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.stat_interval = 10
kernel.sysrq = 0
kernel.watchdog_thresh = 30
kernel.nmi_watchdog = 0
kernel.timer_migration = 0
kernel.core_uses_pid = 1
kernel.hung_task_timeout_secs = 0
kernel.sched_rt_runtime_us = -1
kernel.sched_rt_period_us = -1
kernel.sched_child_runs_first = 1
net.ipv4.tcp_frto=1
net.ipv4.tcp_frto_response=2
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=15" | sudo tee /etc/sysctl.d/99-swappiness.conf
echo -e "Restart swap"
echo -e 1 | sudo tee /proc/sys/vm/drop_caches
echo -e 2 | sudo tee /proc/sys/vm/drop_caches
echo -e 3 | sudo tee /proc/sys/vm/drop_caches
sudo swapoff -av && sudo swapon -av

# ------------------------------------------------------------------------

# Enable trim
sudo systemctl start fstrim.timer
echo -e "Run fstrim"
sudo fstrim -Av

# ------------------------------------------------------------------------

## Remove floppy cdrom
sudo sed -i -e '/^\/\/floppy/d' /etc/fstab
sudo sed -i -e '/^\/\/sr/d' /etc/fstab

# ------------------------------------------------------------------------

## DPKG keep current versions of configs
echo -e 'DPkg::Options {
   "--force-confold";
   "--force-confdef";
};' | sudo tee /etc/apt/apt.conf.d/71debconf
## APT no install suggests
echo -e 'APT::Get::Install-Suggests "false";' | sudo tee /etc/apt/apt.conf.d/95suggests

# ------------------------------------------------------------------------

## Set ulimit to unlimited
ulimit -c unlimited

# ------------------------------------------------------------------------

echo -e "Disable wait online services"
sudo systemctl mask NetworkManager-wait-online.service >/dev/null 2>&1

# ------------------------------------------------------------------------

echo -e "Disable SELINUX"
echo -e "SELINUX=disabled" | sudo tee /etc/selinux/config

# ------------------------------------------------------------------------

echo -e "Disable CONCURRENCY"
echo -e "CONCURRENCY=none" | sudo tee /etc/init.d/rc

# ------------------------------------------------------------------------

## Don't autostart .desktop
sudo sed -i -e 's/NoDisplay=true/NoDisplay=false/g' /etc/xdg/autostart/*.desktop

# ------------------------------------------------------------------------

echo -e "Enable tmpfs ramdisk"
sudo sed -i -e '/^\/\/tmpfs/d' /etc/fstab
echo -e "tmpfs /tmp tmpfs noatime,nosuid 0 0" | sudo tee -a /etc/fstab

# ------------------------------------------------------------------------

## Disable resume from hibernate
echo -e "#" | sudo tee /etc/initramfs-tools/conf.d/resume

# ------------------------------------------------------------------------

## GRUB timeout
sudo sed -i -e 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
sudo update-grub

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
cd

# ------------------------------------------------------------------------

echo -e "Clear the patches"
rm -rfd /{tmp,var/tmp}/{.*,*}
sudo rm -rfd /var/cache/apt/archives/*
sudo rm -rfd /var/lib/dpkg/info/*.postinst
sudo dpkg --configure -a
sudo apt-get clean -y
sudo apt-get autoclean -y
sudo apt-get install -f --assume-yes
sudo apt-get remove -y --purge $(/bin/dpkg -l | /bin/egrep "^rc" | /bin/awk '{print $2}')
sudo apt-get autoremove -y --purge

# ------------------------------------------------------------------------

## Optimize font cache
mkfontscale && mkfontdir && fc-cache -fv && fc-cache ~/.fonts

# ------------------------------------------------------------------------

echo -e "Clean crash log"
sudo rm -rfd /var/crash/*
echo -e "Clean archived journal"
sudo journalctl --rotate --vacuum-time=0.1
sudo sed -i -e 's/^#ForwardToSyslog=yes/ForwardToSyslog=no/' /etc/systemd/journald.conf
sync
