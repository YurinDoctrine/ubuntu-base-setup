#!/usr/bin/env bash
# Before hop in
sudo apt update &&
    sudo apt install -y psmisc systemd git &&
    sudo apt install -y software-properties-common &&
    sudo apt install --no-install-recommends -y kubuntu-restricted-extras

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
find /usr/share/doc/ | egrep "\.gz" | xargs sudo rm -f
find /usr/share/doc/ | egrep "\.pdf" | xargs sudo rm -f
find /usr/share/doc/ | egrep "\.tex" | xargs sudo rm -f
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

    'xscreensaver'       # A screen saver and locker for the X
    'xfburn'             # A simple CD/DVD burning tool
    'xfce4-notifyd'      # Notification Daemon
    'mate-power-manager' # MATE Power Manager
    'suckless-tools'     # Generic menu for X (dmenu)
    'gmrun'              # A lightweight application launcher
    'gsimplecal'         # A simple, lightweight calendar
    'compton'            # A compositor for X11
    'conky'              # A system monitor software for the X Window System
    'featherpad'         # Lightweight Qt plain text editor
    'nitrogen'           # A fast and lightweight desktop background browser and setter for X Window
    'obsession'          # Session Management Helper
    'openbox'            # A lightweight, powerful, and highly configurable stacking window manager
    'scrot'              # Simple command-line screenshot utility
    'udiskie'            # An udisks2 front-end written in python
    'pcmanfm-qt'         # The LXQt file manager
    'tint2'              # A simple, unobtrusive and light panel for Xorg
    'lxappearance'       # Set System Themes
    'lxpolkit'           # LXDE PolicyKit authentication agent
    #'lxdm'               # A lightweight display manager

    # DEVELOPMENT ---------------------------------------------------------

    'fakeroot'    # Tool for simulating superuser privileges
    'python3-pip' # The official package installer for Python

    # --- Audio

    'pavucontrol-qt' # Pulse Audio volume control Qt port
    'pasystray'      # PulseAudio system tray

    # --- Bluetooth

    'blueman' # GTK+ Bluetooth Manager

    # TERMINAL UTILITIES --------------------------------------------------

    'cron'           # Cron jobs
    'dash'           # A POSIX-compliant shell derived from ash
    'fish'           # The friendly interactive shell
    'vsftpd'         # File transfer protocol
    'htop'           # Process viewer
    'neofetch'       # Shows system info when you launch terminal
    'openssh-server' # SSH connectivity tools
    'irssi'          # Terminal based IRC
    'p7zip'          # 7z compression program
    'speedtest-cli'  # Internet speed via terminal
    'terminator'     # A terminal emulator
    'fonts-terminus' # Font package with some bigger fonts for login terminal
    'unrar'          # RAR compression program
    'unzip'          # Zip compression program
    'wget'           # Remote content retrieval
    'nano'           # A simple console based text editor
    'zenity'         # Display graphical dialog boxes via shell scripts
    'zip'            # Zip compression program

    # DISK UTILITIES ------------------------------------------------------

    'gparted' # Disk utility

    # GENERAL UTILITIES ---------------------------------------------------

    'apache2'              # HTTP server
    'apt-cacher'           # A caching proxy for Debian packages
    'arandr'               # Provide a simple visual front end for XRandR
    'catfish'              # Versatile file searching tool
    'dialog'               # A tool to display dialog boxes from shell scripts
    'earlyoom'             # Early OOM Daemon for Linux
    'flameshot'            # Screenshots
    'file-roller'          # Create and modify archives
    'filezilla'            # FTP Client
    'playerctl'            # Utility to control media players via MPRIS
    'putty'                # A port of the popular GUI SSH, Telnet, Rlogin and serial port connection client
    'transmission'         # BitTorrent client
    'net-tools'            # Network utilities
    'nocache'              # Minimize caching effects
    'galculator'           # A simple, elegant calculator
    'gnupg'                # Complete and free implementation of the OpenPGP standard
    'preload'              # Makes applications run faster by prefetching binaries and shared objects
    'simplescreenrecorder' # A feature-rich screen recorder that supports X11 and OpenGL

    # GRAPHICS, VIDEO AND DESIGN ------------------------------------------

    'pinta'    # A simplified alternative to GIMP
    'viewnior' # A simple, fast and elegant image viewer
    'vlc'      # A free and open source cross-platform multimedia player and framework

    # PRINTING ------------------------------------------------------------

    'abiword'     # Fully-featured word processor
    'atril'       # PDF viewer
    'ghostscript' # PostScript interpreter
    'gnumeric'    # A powerful spreadsheet application

)

for PKG in "${PKGS[@]}"; do
    echo -e "INSTALLING: ${PKG}"
    sudo apt --no-install-recommends install -y "$PKG"
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

echo -e "Configuring vconsole.conf to set a larger font for login shell"
echo -e "FONT=ter-v32b" | sudo tee /etc/vconsole.conf

# ------------------------------------------------------------------------

echo -e "Setting laptop lid close to suspend"
sudo sed -i -e 's|#HandleLidSwitch=suspend|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf

# ------------------------------------------------------------------------

echo "Disabling buggy cursor inheritance"
# When you boot with multiple monitors the cursor can look huge. This fixes this...
sudo echo -e "[Icon Theme]
#Inherits=Theme
" | sudo tee /usr/share/icons/default/index.theme

# ------------------------------------------------------------------------

echo -e "Increasing file watcher count"
# This prevents a "too many files" error in Visual Studio Code
echo -e "fs.inotify.max_user_watches=524288" | sudo tee /etc/sysctl.d/40-max-user-watches.conf &&
    sudo sysctl --system

# ------------------------------------------------------------------------

echo -e "Disabling Pulse .esd_auth module"
sudo killall -9 pulseaudio
# Pulse audio loads the `esound-protocol` module, which best I can tell is rarely needed.
# That module creates a file called `.esd_auth` in the home directory which I'd prefer to not be there. So...
sudo sed -i -e 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa
# Restart PulseAudio.
sudo killall -HUP pulseaudio

# ------------------------------------------------------------------------

echo -e "Disabling bluetooth daemon by comment it"
sudo sed -i -e 's|AutoEnable=true|AutoEnable=false|g' /etc/bluetooth/main.conf

# ------------------------------------------------------------------------

# Prevent stupid error beeps*
sudo rmmod pcspkr
echo -e "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

# ------------------------------------------------------------------------

echo -e "Purge unneccasary packages"
sudo apt-get remove --purge -y apport mailutils clipit evince at avahi-daemon avahi-utils geany gigolo gimp hexchat dovecot nfs-kernel-server \
    nfs-common portmap rpcbind rsh-client rsh-redone-client autofs snmp talk telnetd inetutils-telnetd zeitgeist-core zeitgeist-datahub zeitgeist \
    ldap-utils mate-media minetest xinetd pure-ftpd nis xfce4-power-manager
echo -e "Clear the patches"
sudo rm -rfd $HOME/.cache/thumbnails
sudo rm -rfd /var/cache/apt/archives/*
echo -e "Remove snapd and flatpak garbages"
sudo systemctl disable --now snapd
sudo umount /run/snap/ns
sudo systemctl disable snapd.service
sudo systemctl disable snapd.socket
sudo systemctl disable snapd.seeded.service
sudo systemctl disable snapd.autoimport.service
sudo systemctl disable snapd.apparmor.service
sudo rm -f /etc/apparmor.d/usr.lib.snapd.snap-confine.real
sudo systemctl start apparmor.service

sudo apt-get remove --purge snapd -y
sudo apt-mark hold snapd

sudo rm -rfd $HOME/snap
sudo rm -rfd /snap
sudo rm -rfd /var/snap
sudo rm -rfd /var/lib/snapd
sudo rm -rfd /var/cache/snapd
sudo rm -rfd /usr/lib/snapd

flatpak uninstall --all

sudo apt-get remove --purge flatpak -y
sudo apt-mark hold flatpak

sudo apt-get autoremove --purge -y
sudo apt-get autoclean -y
sync

# ------------------------------------------------------------------------

# Implement .config/ files of the openbox
cd /tmp &&
    git clone --branch 11 https://github.com/CBPP/cbpp-icon-theme.git &&
    sudo cp -R cbpp-icon-theme/cbpp-icon-theme/data/usr/share/icons/* /usr/share/icons &&
    git clone --branch 11 https://github.com/CBPP/cbpp-ui-theme.git &&
    sudo cp -R cbpp-ui-theme/cbpp-ui-theme/data/usr/share/themes/* /usr/share/themes &&
    git clone --branch 11 https://github.com/CBPP/cbpp-wallpapers.git &&
    sudo cp -R cbpp-wallpapers/cbpp-wallpapers/data/usr/share/backgrounds/* /usr/share/backgrounds &&
    git clone --branch 11 https://github.com/CBPP/cbpp-pipemenus.git &&
    sudo cp -R cbpp-pipemenus/cbpp-pipemenus/data/usr/bin/* /usr/bin &&
    git clone --branch 11 https://github.com/CBPP/cbpp-configs.git &&
    sudo cp -R cbpp-configs/cbpp-configs/data/usr/bin/* /usr/bin &&
    git clone --branch 11 https://github.com/CBPP/cbpp-lxdm-theme.git &&
    sudo rm -rfd /usr/share/lxdm/themes/*
sudo cp -R cbpp-lxdm-theme/cbpp-lxdm-theme/data/etc/lxdm/* /etc/lxdm
sudo cp -R cbpp-lxdm-theme/cbpp-lxdm-theme/data/usr/share/lxdm/themes/* /usr/share/lxdm/themes
git clone https://github.com/YurinDoctrine/.config.git &&
    sudo cp -R .config/.conkyrc $HOME
sudo cp -R .config/.gmrunrc $HOME
sudo cp -R .config/.gtkrc-2.0 $HOME
sudo cp -R .config/.gtkrc-2.0.mine $HOME
sudo cp -R .config/.Xresources $HOME
sudo cp -R .config/.xscreensaver $HOME
sudo cp -R .config/.fonts.conf $HOME
sudo cp -R .config/.gtk-bookmarks $HOME
sudo cp -R .config/* $HOME/.config
sudo cp -R .config/.conkyrc /etc/skel
sudo cp -R .config/.gmrunrc /etc/skel
sudo cp -R .config/.gtkrc-2.0 /etc/skel
sudo cp -R .config/.gtkrc-2.0.mine /etc/skel
sudo cp -R .config/.Xresources /etc/skel
sudo cp -R .config/.xscreensaver /etc/skel
sudo cp -R .config/.fonts.conf /etc/skel
sudo cp -R .config/.gtk-bookmarks /etc/skel
sudo cp -R .config/.conkyrc /root
sudo cp -R .config/.gmrunrc /root
sudo cp -R .config/.gtkrc-2.0 /root
sudo cp -R .config/.gtkrc-2.0.mine /root
sudo cp -R .config/.Xresources /root
sudo cp -R .config/.xscreensaver /root
sudo cp -R .config/.fonts.conf /root
sudo cp -R .config/.gtk-bookmarks /root
sudo mkdir /etc/skel/.config
sudo cp -R .config/* /etc/skel/.config
sudo mkdir /root/.config
sudo cp -R .config/* /root/.config
sudo chmod 0755 /home/$USER/.config/dmenu/dmenu-bind.sh
sudo chmod 0755 /etc/skel/.config/dmenu/dmenu-bind.sh
sudo chmod 0755 /root/.config/dmenu/dmenu-bind.sh
sudo chmod 0755 /etc/skel/.config/cbpp-exit
sudo chmod 0755 /etc/skel/.config/cbpp-help-pipemenu
sudo chmod 0755 /etc/skel/.config/cbpp-compositor
sudo chmod 0755 /etc/skel/.config/cbpp-places-pipemenu
sudo chmod 0755 /etc/skel/.config/cbpp-welcome
sudo mv /etc/skel/.config/cbpp-exit /usr/bin
sudo mv /etc/skel/.config/cbpp-help-pipemenu /usr/bin
sudo mv /etc/skel/.config/cbpp-compositor /usr/bin
sudo mv /etc/skel/.config/cbpp-places-pipemenu /usr/bin
sudo mv /etc/skel/.config/cbpp-welcome /usr/bin
sudo find /home/$USER/.config/ | egrep "\cbpp-" | xargs sudo rm -f
sudo find /root/.config/ | egrep "\cbpp-" | xargs sudo rm -f

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
        sudo ln -sfT dash /usr/bin/sh # Link dash to /usr/bin/sh
        extra
    elif [[ "$ans" == "no" ]]; then
        echo -e "LEAVING ..."
        echo -e ""
        echo -e "FINAL: DO YOU ALSO WANT TO RUN THE AUTHOR'S secure-linux?"
        read -p $'yes/no >_: ' noc
        if [[ "$noc" == "yes" ]]; then
            echo -e "RUNNING ..."
            chsh -s /usr/bin/fish         # Change default shell before leaving.
            sudo ln -sfT dash /usr/bin/sh # Link dash to /usr/bin/sh
            extra2
        elif [[ "$noc" == "no" ]]; then
            echo -e "LEAVING ..."
            chsh -s /usr/bin/fish         # Change default shell before leaving.
            sudo ln -sfT dash /usr/bin/sh # Link dash to /usr/bin/sh
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
