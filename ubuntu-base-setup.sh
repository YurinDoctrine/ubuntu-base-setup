#!/bin/bash
# Before hop in
sudo apt update &&
    sudo apt install -y git &&
    sudo apt install -y apt-cacher trafficserver &&
    sudo apt install --install-recommends -y kubuntu-restricted-extras software-properties-common

# ------------------------------------------------------------------------

# Setting up locales
echo -e "LANG=en_GB.UTF8" | sudo tee -a /etc/environment
echo -e "LC_ALL=en_GB.UTF8" | sudo tee -a /etc/environment
sudo sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen en_GB.UTF-8
localectl set-locale LANG=en_GB.UTF-8 LC_TIME=en_GB.UTF-8

# ------------------------------------------------------------------------

# Don't reserve space man-pages, locales, licenses.
echo -e "Remove useless companies"
find /usr/share/doc -depth -type f ! -name copyright | xargs sudo rm -rf || true
find /usr/share/doc -empty | xargs sudo rmdir || true
find /usr/share/doc | egrep "\.gz" | xargs sudo rm -rf
find /usr/share/doc | egrep "\.pdf" | xargs sudo rm -rf
find /usr/share/doc | egrep "\.tex" | xargs sudo rm -rf
sudo rm -rf /usr/share/groff/* /usr/share/info/*
sudo rm -rf /usr/share/lintian/* /usr/share/linda/* /var/cache/man/*
sudo rm -rf /usr/share/man/*
dpkg -l | grep '^ii.*texlive.*doc'
sudo apt remove --purge \
    texlive-fonts-recommended-doc texlive-latex-base-doc texlive-latex-extra-doc \
    texlive-latex-recommended-doc texlive-pictures-doc texlive-pstricks-doc

echo -e "path-exclude /usr/share/doc/*
# we need to keep copyright files for legal reasons
path-include /usr/share/doc/*/copyright
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
    \
    'xscreensaver'            # A screen saver and locker for the X
    'xfce4-power-manager'     # Power Manager
    'xfce4-notifyd'           # Notification indicator
    'xfce4-pulseaudio-plugin' # Xfce4 panel plugin icon to control Pulseaudio
    'xorg-backlight'          # RandR-based backlight control application
    'suckless-tools'          # Generic menu for X (dmenu)
    'gmrun'                   # A lightweight application launcher
    'gsimplecal'              # A simple, lightweight calendar
    'ibus'                    # An input method framework
    'compton'                 # A compositor for X11
    'conky'                   # A system monitor software for the X Window System
    'nitrogen'                # A fast and lightweight desktop background browser and setter for X Window
    'openbox'                 # A lightweight, powerful, and highly configurable stacking window manager
    'tint2'                   # A simple, unobtrusive and light panel for Xorg
    'lxpolkit'                # A toolkit for defining and handling authorizations
    'lxappearance'            # Set System Themes
    'qt5-style-plugins'       # Additional style plugins for Qt5

    # DEVELOPMENT ---------------------------------------------------------
    \
    'ccache'         # Compiler cacher
    'clang'          # C Lang compiler
    'cmake'          # Cross-platform open-source make system
    'fakeroot'       # Tool for simulating superuser privileges
    'gcc'            # C/C++ compiler
    'glibc'          # C libraries
    'glslang'        # OpenGL and OpenGL ES shader front end and validator
    'meld'           # File/directory comparison
    'mariadb-server' # Commercially supported fork of the MySQL
    'meson'          # Build system that use python as a front-end language and Ninja as a building backend
    'nodejs'         # Javascript runtime environment
    'npm'            # Node package manager
    'php'            # Scripting language

    # --- Networking Setup
    \
    'wpasupplicant'          # Key negotiation for WPA wireless networks
    'dialog'                 # Enables shell scripts to trigger dialog boxes
    'openvpn'                # Open VPN support
    'networkmanager-openvpn' # Open VPN plugin for NM
    'network-manager-gnome'  # System tray icon/utility for network connectivity
    'libsecret'              # Library for storing passwords
    'dhclient'               # DHCP client

    # --- Audio
    \
    'alsa-utils'      # Advanced Linux Sound Architecture (ALSA) Components https://alsa.opensrc.org/
    'alsa-plugins'    # ALSA plugins
    'pulseaudio'      # Pulse Audio sound components
    'pulseaudio-alsa' # ALSA configuration for pulse audio
    'pavucontrol'     # Pulse Audio volume control
    'pasystray'       # PulseAudio system tray

    # --- Bluetooth
    \
    'bluez'                       # Daemons for the bluetooth protocol stack
    'bluez-libs'                  # Daemons for the bluetooth libraries
    'bluez-utils'                 # Bluetooth development and debugging utilities
    'bluez-firmware'              # Firmwares for Broadcom BCM203x and STLC2300 Bluetooth chips
    'blueberry'                   # Bluetooth configuration tool
    'pulseaudio-module-bluetooth' # Bluetooth support for PulseAudio

    # TERMINAL UTILITIES --------------------------------------------------
    \
    'cron'          # Cron jobs
    'fish'          # The friendly interactive shell
    'vsftpd'        # File transfer protocol
    'hardinfo'      # Hardware info app
    'htop'          # Process viewer
    'neofetch'      # Shows system info when you launch terminal
    'openssh'       # SSH connectivity tools
    'irssi'         # Terminal based IRC
    'p7zip'         # 7z compression program
    'rsync'         # Remote file sync utility
    'fonts-roboto'  # Font package
    'speedtest-cli' # Internet speed via terminal
    'terminator'    # A terminal emulator
    'terminus-font' # Font package with some bigger fonts for login terminal
    'unrar'         # RAR compression program
    'unzip'         # Zip compression program
    'wget'          # Remote content retrieval
    'vim'           # Terminal Editor
    'zenity'        # Display graphical dialog boxes via shell scripts
    'zip'           # Zip compression program

    # DISK UTILITIES ------------------------------------------------------
    \
    'android-tools-adb'     # ADB for Android
    'android-file-transfer' # Android File Transfer
    'autofs'                # Auto-mounter
    'btrfs-progs'           # BTRFS Support
    'dosfstools'            # DOS Support
    'exfat-utils'           # Mount exFat drives
    'gparted'               # Disk utility
    'gvfs'                  # More File System Stuff
    'ntfs-3g'               # Open source implementation of NTFS file system
    'parted'                # Disk utility
    'samba'                 # Samba File Sharing
    'smartmontools'         # Disk Monitoring
    'smbclient'             # SMB Connection
    'xfsprogs'              # XFS Support

    # GENERAL UTILITIES ---------------------------------------------------
    \
    'flameshot'           # Screenshots
    'file-roller'         # Create and modify archives
    'freerdp'             # RDP Connections
    'libvncserver'        # VNC Connections
    'filezilla'           # FTP Client
    'apache2'             # HTTP server
    'apt-transport-https' # HTTPS download transport for APT
    'playerctl'           # Utility to control media players via MPRIS
    'remmina'             # Remote Connection
    'transmission'        # BitTorrent client
    'net-tools'           # Network utilities
    'veracrypt'           # Disc encryption utility
    'variety'             # Wallpaper changer
    'gnupg'               # Complete and free implementation of the OpenPGP standard
    'gtkhash'             # Checksum verifier
    'zram-config'         # zRAM loader

    # GRAPHICS, VIDEO AND DESIGN -------------------------------------------------
    \
    'gcolor2'   # Colorpicker
    'gimp'      # GNU Image Manipulation Program
    'ristretto' # Multi image viewer
    'kdenlive'  # Movie Render

    # PRINTING --------------------------------------------------------
    \
    'xpdf'                  # PDF viewer
    'cups'                  # Open source printer drivers
    'cups-pdf'              # PDF support for cups
    'ghostscript'           # PostScript interpreter
    'gsfonts'               # Adobe Postscript replacement fonts
    'hplip'                 # HP Drivers
    'system-config-printer' # Printer setup  utility

)

for PKG in "${PKGS[@]}"; do
    echo -e "INSTALLING: ${PKG}"
    sudo apt install -y "$PKG"
done

echo -e "Done!"

# ------------------------------------------------------------------------

echo -e "FINAL SETUP AND CONFIGURATION"

# Sudo rights
echo -e "Add sudo rights"
sudo sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo -e "Remove no password sudo rights"
sudo sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# ------------------------------------------------------------------------

echo -e "Configuring vconsole.conf to set a larger font for login shell"
echo -e "FONT=ter-v32b" | sudo tee /etc/vconsole.conf

# ------------------------------------------------------------------------

echo -e "Setting laptop lid close to suspend"
sudo sed -i -e 's|[# ]*HandleLidSwitch[ ]*=[ ]*.*|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf

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
sudo sed -i 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa
# Start/restart PulseAudio.
sudo killall -HUP pulseaudio

# ------------------------------------------------------------------------

echo -e "Disabling bluetooth daemon by comment it"
sudo sed -i 's|AutoEnable|#AutoEnable|g' /etc/bluetooth/main.conf

# ------------------------------------------------------------------------

# Prevent stupid error beeps*
sudo rmmod pcspkr
echo -e "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

# ------------------------------------------------------------------------

echo -e "Increase zRAM size"
sudo sed -i 's/totalmem\ \/\ 2/totalmem\ \/\ 4/' /usr/bin/init-zram-swapping

# ------------------------------------------------------------------------

# Same theme for Qt/KDE applications and GTK applications, and fix missing indicators
echo -e "XDG_CURRENT_DESKTOP=Unity
QT_QPA_PLATFORMTHEME=gtk2" | sudo tee -a /etc/environment

# ------------------------------------------------------------------------

sudo rm -rf ~/.cache/thumbnails
echo -e "Clear the patches"
sudo rm -rf /var/cache/apt/archives/*
echo -e "Remove snapd and flatpak garbages"
sudo systemctl disable --now snapd
sudo umount /run/snap/ns
sudo systemctl disable snapd.service
sudo systemctl disable snapd.socket
sudo systemctl disable snapd.seeded.service
sudo systemctl disable snapd.autoimport.service
sudo systemctl disable snapd.apparmor.service
sudo rm -rf /etc/apparmor.d/usr.lib.snapd.snap-confine.real
sudo systemctl start apparmor.service

sudo apt remove --purge snapd -y
sudo apt-mark hold snapd

sudo rm -rf ~/snap
sudo rm -rf /snap
sudo rm -rf /var/snap
sudo rm -rf /var/lib/snapd
sudo rm -rf /var/cache/snapd
sudo rm -rf /usr/lib/snapd

flatpak uninstall --all

sudo apt remove --purge flatpak -y
sudo apt-mark hold flatpak
sudo apt autopurge -y
sync

# ------------------------------------------------------------------------

# delete motd ads (really, canonical?)
sudo rm -rf /etc/update-motd.d/*motd-news

# ------------------------------------------------------------------------

# Implement .config/ files of the openbox
cd /tmp &&
    git clone https://github.com/YurinDoctrine/.config.git &&
    sudo cp -R .config/.conkyrc ~ &&
    sudo cp -R .config/.gmrunrc ~ &&
    sudo cp -R .config/.gtkrc-2.0 ~ &&
    sudo cp -R .config/* ~/.config &&
    git clone --branch 10 https://github.com/CBPP/cbpp-icon-theme.git &&
    sudo cp -R cbpp-icon-theme/cbpp-icon-theme/data/usr/share/icons/* /usr/share/icons &&
    git clone --branch 10 https://github.com/CBPP/cbpp-ui-theme.git &&
    sudo cp -R cbpp-ui-theme/cbpp-ui-theme/data/usr/share/themes/* /usr/share/themes &&
    git clone --branch 10 https://github.com/CBPP/cbpp-wallpapers.git &&
    sudo cp -R cbpp-wallpapers/cbpp-wallpapers/data/usr/share/backgrounds/* /usr/share/backgrounds &&
    git clone --branch 10 https://github.com/CBPP/cbpp-slim.git &&
    sudo cp -R cbpp-slim/cbpp-slim/data/usr/bin/* /usr/bin &&
    git clone --branch 10 https://github.com/CBPP/cbpp-exit.git &&
    sudo cp -R cbpp-exit/cbpp-exit/data/usr/bin/* /usr/bin &&
    git clone --branch 10 https://github.com/CBPP/cbpp-pipemenus.git &&
    sudo cp -R cbpp-pipemenus/cbpp-pipemenus/data/usr/bin/* /usr/bin &&
    cd

# ------------------------------------------------------------------------

echo -e "
###############################################################################
# All done! Would you also mind to run the author's ultra-gaming-setup-wizard?
###############################################################################
"

extra() {
    curl -fsSL https://raw.githubusercontent.com/YurinDoctrine/ultra-gaming-setup-wizard/main/ultra-gaming-setup-wizard.sh >ultra-gaming-setup-wizard.sh &&
        chmod 755 ultra-gaming-setup-wizard.sh &&
        ./ultra-gaming-setup-wizard.sh
}
extra2() {
    curl -fsSL https://raw.githubusercontent.com/YurinDoctrine/secure-linux/master/secure.sh >secure.sh &&
        chmod 755 secure.sh &&
        ./secure.sh
}

final() {
    read -p $'yes/no >_: ' ans
    if [[ "$ans" == "yes" ]]; then
        echo -e "RUNNING ..."
        chsh -s /usr/bin/fish # Change default shell before leaving.
        extra
    elif [[ "$ans" == "no" ]]; then
        echo -e "LEAVING ..."
        echo -e ""
        echo -e "FINAL: DO YOU ALSO WANT TO RUN THE AUTHOR'S secure-linux?"
        read -p $'yes/no >_: ' noc
        if [[ "$noc" == "yes" ]]; then
            echo -e "RUNNING ..."
            chsh -s /usr/bin/fish # Change default shell before leaving.
            extra2
        elif [[ "$noc" == "no" ]]; then
            echo -e "LEAVING ..."
            chsh -s /usr/bin/fish # Change default shell before leaving.
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
