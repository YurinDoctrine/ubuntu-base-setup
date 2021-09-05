#!/usr/bin/env bash
# Before hop in
sudo apt update &&
    sudo apt install -f --assume-yes 9base curl git software-properties-common wget &&
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
timedatectl set-ntp true
timedatectl set-timezone Europe/Moscow

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

    'powertop' # A tool to diagnose issues with power consumption and power management
    'preload'  # Makes applications run faster by prefetching binaries and shared objects

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

# Suppress the task timeout messages Ubuntu spams
echo -e 0 | sudo tee /proc/sys/kernel/hung_task_timeout_secs

# ------------------------------------------------------------------------

# Prevent motd news*
sudo sed -i -e 's/ENABLED=.*/ENABLED=0/' /etc/default/motd-news
sudo systemctl mask motd-news.timer

# ------------------------------------------------------------------------

# btrfs tweaks if disk is
sudo btrfs balance start -musage=50 -dusage=50 /

# ------------------------------------------------------------------------

echo -e "Apply disk tweaks"
sudo sed -i -e 's| defaults | defaults,noatime,commit=60 |g' /etc/fstab
sudo sed -i -e 's| errors=remount-ro 0 | noatime,commit=60,errors=remount-ro 0 |g' /etc/fstab

# ------------------------------------------------------------------------

# Tune swappiness value
sudo sed -i -e '/\/swappiness/d' /etc/sysctl.conf
echo -e "vm.swappiness=1" | sudo tee /etc/sysctl.d/99-swappiness.conf

# ------------------------------------------------------------------------

# Enable trim
sudo systemctl start fstrim.timer

# ------------------------------------------------------------------------

## Remove floppy cdrom
sudo sed -i -e '/\/floppy/d' /etc/fstab
sudo sed -i -e '/\/sr/d' /etc/fstab

# ------------------------------------------------------------------------

## DPKG keep current versions of configs
echo -e 'Dpkg::Options {
   "--force-confold";
   "--force-confdef";
};' | sudo tee /etc/apt/apt.conf.d/71debconf

# ------------------------------------------------------------------------

## Set ulimit to unlimited
ulimit -c unlimited

# ------------------------------------------------------------------------

echo -e "Disable wait online services"
sudo systemctl disable NetworkManager-wait-online.service

# ------------------------------------------------------------------------

echo -e "Disable SELINUX"
echo -e "SELINUX=disabled" | sudo tee /etc/selinux/config

# ------------------------------------------------------------------------

## GRUB timeout
sudo sed -i -e 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
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
sudo apt-get remove -y --purge $(/bin/dpkg -l | /bin/egrep "^rc" | /bin/awk '{print $2}')
sudo apt-get remove -y --purge $(/bin/dpkg -l | /bin/egrep "\-doc " | /bin/awk '{print $2}')
sudo apt-get install -f --assume-yes
sudo apt-get autoremove -y --purge

# ------------------------------------------------------------------------

## Optimize font cache
mkfontscale && mkfontdir && fc-cache -fv

# ------------------------------------------------------------------------

echo -e "Clean archived journal"
sudo journalctl --rotate --vacuum-size=1M
sudo sed -i -e 's/^#ForwardToSyslog=yes/ForwardToSyslog=no/' /etc/systemd/journald.conf
sync
