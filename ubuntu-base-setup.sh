#!/usr/bin/env bash
# Before hop in
sudo apt update &&
    sudo apt install -y --no-install-recommends 9base build-essential curl kitty procps psmisc pulseaudio network-manager systemd git xorg &&
    sudo apt install --install-recommends -y software-properties-common &&
    sudo apt install -y --no-install-recommends kubuntu-restricted-extras kubuntu-restricted-addons

# ------------------------------------------------------------------------

# Setting up locales
echo -e "LANG=en_GB.UTF8" | sudo tee -a /etc/locale.conf
echo -e "LANG=en_GB.UTF8" | sudo tee -a /etc/environment
echo -e "LC_ALL=en_GB.UTF8" | sudo tee -a /etc/environment
sudo sed -i -e 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen en_GB.UTF-8
localectl set-locale LANG=en_GB.UTF-8 LC_TIME=en_GB.UTF-8

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

# This may take time
echo -e "Installing Base System"

PKGS=(
    # --- Importants

    'arandr'               # Provide a simple visual front end for XRandR
    'engrampa'             # Archive manipulator for MATE
    'mate-power-manager'   # MATE Power Manager
    'mksh'                 # MirBSD Korn Shell
    'suckless-tools'       # Simple commands for minimalistic window managers
    'gmrun'                # A lightweight application launcher
    'gsimplecal'           # A simple, lightweight calendar
    'conky'                # A system monitor software for the X Window System
    'dunst'                # Customizable and lightweight notification-daemon
    'featherpad'           # Lightweight Qt plain text editor
    'openbox'              # A lightweight, powerful, and highly configurable stacking window manager
    'scrot'                # Simple command-line screenshot utility
    'udiskie'              # An udisks2 front-end written in python
    'pcmanfm-qt'           # The LXQt file manager
    'ranger'               # A file manager with vi key bindings written in python but with an interface that rocks
    'simplescreenrecorder' # A feature-rich screen recorder that supports X11 and OpenGL
    'tint2'                # A simple, unobtrusive and light panel for Xorg
    'xwallpaper'           # A lightweight and simple desktop background setter for X Window
    'xcompmgr'             # A simple composite manager
    'lxappearance'         # Set System Themes
    'lxpolkit'             # LXDE PolicyKit authentication agent
    #'lxdm'                 # A lightweight display manager

    # --- Network

    'filezilla'        # FTP Client
    'irssi'            # Terminal based IRC
    'transmission-gtk' # BitTorrent client

    # GENERAL UTILITIES ---------------------------------------------------

    'nocache'  # Minimize caching effects
    'powertop' # A tool to diagnose issues with power consumption and power management
    'preload'  # Makes applications run faster by prefetching binaries and shared objects

    # DEVELOPMENT ---------------------------------------------------------

    'ccache' # Compiler cacher

    # --- Audio

    'alsaplayer-common' # A heavily multi-threaded PCM player
    'pasystray'         # PulseAudio system tray
    'playerctl'         # Utility to control media players via MPRIS
    'pulsemixer'        # CLI and curses mixer for PulseAudio

    # --- Bluetooth

    'blueman' # GTK+ Bluetooth Manager

    # TERMINAL UTILITIES --------------------------------------------------

    'fish'   # The friendly interactive shell
    'htop'   # Interactive process viewer
    'neovim' # Fork of Vim aiming to improve user experience, plugins, and GUIs

    # DISK UTILITIES ------------------------------------------------------

    'gparted' # Disk utility

    # GRAPHICS, VIDEO AND DESIGN ------------------------------------------

    'pinta'    # A simplified alternative to GIMP
    'viewnior' # A simple, fast and elegant image viewer
    'vlc'      # A free and open source cross-platform multimedia player and framework

    # PRINTING ------------------------------------------------------------

    'abiword'               # Fully-featured word processor
    'atril'                 # PDF viewer
    'cups'                  # The CUPS Printing System - daemon package
    'gnumeric'              # A powerful spreadsheet application
    'system-config-printer' # A CUPS printer configuration tool and status applet

)

for PKG in "${PKGS[@]}"; do
    echo -e "INSTALLING: ${PKG}"
    sudo apt install -y --no-install-recommends "$PKG"
done

echo -e "Done!"

# ------------------------------------------------------------------------

echo -e "FINAL SETUP AND CONFIGURATION"

# Sudo rights
echo -e "Add sudo rights"
sudo sed -i -e 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo -e "Remove no password sudo rights"
sudo sed -i -e 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# ------------------------------------------------------------------------

echo -e "Display asterisks when sudo"
echo -e "Defaults        pwfeedback" | sudo tee -a /etc/sudoers

# ------------------------------------------------------------------------

echo -e "Configuring vconsole.conf to set a larger font for login shell"
echo -e "FONT=ter-v32b" | sudo tee /etc/vconsole.conf

# ------------------------------------------------------------------------

echo -e "Setting laptop lid close to suspend"
sudo sed -i -e 's|#HandleLidSwitch=suspend|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf

# ------------------------------------------------------------------------

echo -e "Disabling buggy cursor inheritance"
# When you boot with multiple monitors the cursor can look huge. This fixes that...
echo -e "[Icon Theme]
#Inherits=Theme
" | sudo tee /usr/share/icons/default/index.theme

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

echo -e "Disable bluez daemon(opt-out)"
sudo systemctl disable --now bluetooth.service

# ------------------------------------------------------------------------

echo -e "Disable cups daemon(opt-out)"
sudo systemctl disable --now cups.service

# ------------------------------------------------------------------------

# btrfs tweaks if disk is
sudo btrfs scrub start /
sudo btrfs balance start -musage=50 -dusage=50 /

# ------------------------------------------------------------------------

echo -e "Apply disk tweaks"
sudo sed -i -e 's|defaults |defaults,noatime,commit=60 |g' /etc/fstab
sudo sed -i -e 's|errors=remount-ro 0 |noatime,commit=60,errors=remount-ro 0 |g' /etc/fstab

# ------------------------------------------------------------------------

# Tune swappiness value
echo -e "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf

# ------------------------------------------------------------------------

echo -e "Apply powertop tunes"
sudo powertop --auto-tune
sudo systemctl enable --now powertop.service

# ------------------------------------------------------------------------

echo -e "Purge unneccasary packages"
sudo apt-get remove -y --purge apport mailutils clipit compton evince at avahi-daemon avahi-utils geany gigolo gimp hexchat dovecot nfs-kernel-server \
    nfs-common evolution rsh-client rsh-redone-client autofs snmp talk telnetd inetutils-telnetd zeitgeist-core zeitgeist-datahub zeitgeist galculator \
    ldap-utils mate-media minetest xinetd pure-ftpd file-roller catfish obconf terminator thunar thunar-data xfce4-power-manager xfburn xfce4-notifyd \
    deja-dup ibus nis nitrogen samba-common gstreamer1.0-fluendo-mp3 geary rhythmbox rpcbind shotwell thunderbird xfce4-screenshooter xfconf mousepad \
    libreoffice libreoffice-base-core libreoffice-core obsession pavucontrol xfce4-goodies xscreensaver xtightvncviewer
sudo apt-mark hold apport
echo -e "Remove snapd and flatpak garbages"
sudo systemctl disable --now snapd
sudo umount /run/snap/ns
sudo systemctl disable snapd.service
sudo systemctl disable snapd.socket
sudo systemctl disable snapd.seeded.service
sudo systemctl disable snapd.autoimport.service
sudo systemctl disable snapd.apparmor.service

sudo rm -f /etc/apparmor.d/usr.lib.snapd.snap-confine.real

sudo apt-get remove -y --purge snapd
sudo apt-mark hold snapd

sudo rm -rfd $HOME/snap
sudo rm -rfd /snap
sudo rm -rfd /var/snap
sudo rm -rfd /var/lib/snapd
sudo rm -rfd /var/cache/snapd
sudo rm -rfd /usr/lib/snapd

flatpak uninstall --all

sudo apt-get remove -y --purge flatpak
sudo apt-mark hold flatpak

# ------------------------------------------------------------------------

echo -e "Clear the patches"
sudo apt-get autoremove -y --purge
sudo apt-get autoclean
sudo apt-get clean
sudo rm -rfd $HOME/.cache/thumbnails
sudo rm -rfd /var/cache/apt/archives/*
sync

# ------------------------------------------------------------------------

# Implement .config/ files of the openbox
cd /tmp &&
    sudo rm -rfd /usr/share/icons/CBPP
git clone --branch 11 https://github.com/CBPP/cbpp-icon-theme.git &&
    sudo cp -R cbpp-icon-theme/cbpp-icon-theme/data/usr/share/icons/* /usr/share/icons &&
    sudo rm -rfd /usr/share/themes/CBPP
git clone --branch 11 https://github.com/CBPP/cbpp-ui-theme.git &&
    sudo cp -R cbpp-ui-theme/cbpp-ui-theme/data/usr/share/themes/* /usr/share/themes &&
    sudo mkdir /usr/share/backgrounds
sudo rm -rfd /usr/share/backgrounds/*
git clone --branch 11 https://github.com/CBPP/cbpp-wallpapers.git &&
    sudo cp -R cbpp-wallpapers/cbpp-wallpapers/data/usr/share/backgrounds/* /usr/share/backgrounds &&
    git clone --branch 11 https://github.com/CBPP/cbpp-lxdm-theme.git &&
    sudo rm -rfd /usr/share/lxdm/themes/*
sudo cp -R cbpp-lxdm-theme/cbpp-lxdm-theme/data/etc/lxdm/* /etc/lxdm
sudo cp -R cbpp-lxdm-theme/cbpp-lxdm-theme/data/usr/share/lxdm/themes/* /usr/share/lxdm/themes
sudo rm -rfd /home/$USER/.config/*
sudo rm -rfd /etc/skel/.config/*
git clone https://github.com/YurinDoctrine/.config.git &&
    sudo cp -R .config/.conkyrc $HOME
sudo cp -R .config/.gmrunrc $HOME
sudo cp -R .config/.gtkrc-2.0 $HOME
sudo cp -R .config/.gtkrc-2.0.mine $HOME
sudo cp -R .config/.fonts.conf $HOME
sudo cp -R .config/.gtk-bookmarks $HOME
sudo cp -R .config/* $HOME/.config
sudo cp -R .config/.conkyrc /etc/skel
sudo cp -R .config/.gmrunrc /etc/skel
sudo cp -R .config/.gtkrc-2.0 /etc/skel
sudo cp -R .config/.gtkrc-2.0.mine /etc/skel
sudo cp -R .config/.fonts.conf /etc/skel
sudo cp -R .config/.gtk-bookmarks /etc/skel
sudo cp -R .config/.conkyrc /root
sudo cp -R .config/.gmrunrc /root
sudo cp -R .config/.gtkrc-2.0 /root
sudo cp -R .config/.gtkrc-2.0.mine /root
sudo cp -R .config/.fonts.conf /root
sudo cp -R .config/.gtk-bookmarks /root
sudo mkdir /etc/skel/.config
sudo cp -R .config/* /etc/skel/.config
sudo mkdir /root/.config
sudo cp -R .config/* /root/.config
sudo mv /etc/skel/.config/conkywonky /usr/bin
sudo mv /etc/skel/.config/tint2restart /usr/bin
sudo mv /etc/skel/.config/cbpp-exit /usr/bin
sudo mv /etc/skel/.config/cbpp-gksudo /usr/bin
sudo mv /etc/skel/.config/cbpp-help-pipemenu /usr/bin
sudo mv /etc/skel/.config/cbpp-compositor /usr/bin
sudo mv /etc/skel/.config/cbpp-include.cfg /usr/bin
sudo mv /etc/skel/.config/cbpp-places-pipemenu /usr/bin
sudo mv /etc/skel/.config/cbpp-recent-files-pipemenu /usr/bin
sudo mv /etc/skel/.config/cbpp-welcome /usr/bin
sudo find /home/$USER/.config/ | egrep '\cbpp-' | xargs sudo rm -f
sudo find /root/.config/ | egrep '\cbpp-' | xargs sudo rm -f
sudo find /home/$USER/.config/ | egrep '\conkywonky' | xargs sudo rm -f
sudo find /root/.config/ | egrep '\conkywonky' | xargs sudo rm -f
sudo find /home/$USER/.config/ | egrep '\tint2restart' | xargs sudo rm -f
sudo find /root/.config/ | egrep '\tint2restart' | xargs sudo rm -f

echo -e "XDG_CURRENT_DESKTOP=LXDE
QT_QPA_PLATFORMTHEME=gtk2" | sudo tee -a /etc/environment

# ------------------------------------------------------------------------

extra() {
    curl -fsSL https://raw.githubusercontent.com/YurinDoctrine/ultra-gaming-setup-wizard/main/ultra-gaming-setup-wizard.sh >ultra-gaming-setup-wizard.sh &&
        chmod 0755 ultra-gaming-setup-wizard.sh &&
        ./ultra-gaming-setup-wizard.sh
}

extra2() {
    curl -fsSL https://raw.githubusercontent.com/YurinDoctrine/secure-linux/master/secure.sh >secure.sh &&
        chmod 0755 secure.sh &&
        ./secure.sh
}

final() {

    sleep 0.3 && clear
    echo -e "
###############################################################################
# All Done! Would you also mind to run the author's ultra-gaming-setup-wizard?
###############################################################################
"

    read -p $'yes/no >_: ' ans
    if [[ "$ans" == "yes" ]]; then
        echo -e "RUNNING ..."
        chsh -s /usr/bin/fish         # Change default shell before leaving.
        sudo ln -sfT mksh /usr/bin/sh # Link mksh to /usr/bin/sh
        extra
    elif [[ "$ans" == "no" ]]; then
        echo -e "LEAVING ..."
        echo -e ""
        echo -e "FINAL: DO YOU ALSO WANT TO RUN THE AUTHOR'S secure-linux?"
        read -p $'yes/no >_: ' noc
        if [[ "$noc" == "yes" ]]; then
            echo -e "RUNNING ..."
            chsh -s /usr/bin/fish         # Change default shell before leaving.
            sudo ln -sfT mksh /usr/bin/sh # Link mksh to /usr/bin/sh
            extra2
        elif [[ "$noc" == "no" ]]; then
            echo -e "LEAVING ..."
            chsh -s /usr/bin/fish         # Change default shell before leaving.
            sudo ln -sfT mksh /usr/bin/sh # Link mksh to /usr/bin/sh
            exit 0
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
