#!/bin/bash

# ------------------------------------------------------------------------

# Before hop in
sudo apt update &&
    sudo apt install -y git

# ------------------------------------------------------------------------

# No acquire languages
echo -e 'Acquire::Languages "none";' | sudo tee -a /etc/apt/apt.conf.d/90nolanguages

# ------------------------------------------------------------------------

# Setting up locales
echo -e "Setup language to en_GB and set locale"
sudo sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
sudo timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_GB.UTF-8" LC_TIME="en_GB.UTF-8"

# ------------------------------------------------------------------------

# Sudo rights
echo -e "Add sudo rights"
sudo sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo -e "Remove no password sudo rights"
sudo sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# ------------------------------------------------------------------------

# This may take time
echo -e "Installing Base System"

PKGS=(
    # --- Importants
    \
    'ubuntu-restricted-extras'   # add-repository command
    'software-properties-common' # Same above

    # --- Setup Desktop
    \
    'xfce4-power-manager' # Power Manager
    'rofi'                # Menu System
    'picom'               # Translucent Windows
    'xclip'               # System Clipboard
    'lxappearance'        # Set System Themes

    # --- Networking Setup
    \
    'wpasupplicant'          # Key negotiation for WPA wireless networks
    'dialog'                 # Enables shell scripts to trigger dialog boxes
    'openvpn'                # Open VPN support
    'networkmanager-openvpn' # Open VPN plugin for NM
    'network-manager-applet' # System tray icon/utility for network connectivity
    'libsecret'              # Library for storing passwords

    # --- Audio
    \
    'alsa-utils'      # Advanced Linux Sound Architecture (ALSA) Components https://alsa.opensrc.org/
    'alsa-plugins'    # ALSA plugins
    'pulseaudio'      # Pulse Audio sound components
    'pulseaudio-alsa' # ALSA configuration for pulse audio
    'pavucontrol'     # Pulse Audio volume control
    'pnmixer'         # System tray volume control

    # --- Bluetooth
    \
    'bluez'                       # Daemons for the bluetooth protocol stack
    'pulseaudio-module-bluetooth' # Bluetooth support for PulseAudio

    # TERMINAL UTILITIES --------------------------------------------------
    \
    'cron'                # cron jobs
    'file-roller'         # Archive utility
    'hardinfo'            # Hardware info app
    'htop'                # Process viewer
    'neofetch'            # Shows system info when you launch terminal
    'ntp'                 # Network Time Protocol to set time via network.
    'openssh'             # SSH connectivity tools
    'p7zip'               # 7z compression program
    'rsync'               # Remote file sync utility
    'speedtest-cli'       # Internet speed via terminal
    'terminus-font'       # Font package with some bigger fonts for login terminal
    'unrar'               # RAR compression program
    'unzip'               # Zip compression program
    'wget'                # Remote content retrieval
    'terminator'          # Terminal emulator
    'vim'                 # Terminal Editor
    'zenity'              # Display graphical dialog boxes via shell scripts
    'zip'                 # Zip compression program
    'zsh'                 # ZSH shell
    'zsh-autosuggestions' # Tab completion for ZSH

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
    'nautilus-share'        # File Sharing in Nautilus
    'ntfs-3g'               # Open source implementation of NTFS file system
    'parted'                # Disk utility
    'samba'                 # Samba File Sharing
    'smartmontools'         # Disk Monitoring
    'smbclient'             # SMB Connection
    'xfsprogs'              # XFS Support

    # GENERAL UTILITIES ---------------------------------------------------
    \
    'flameshot'    # Screenshots
    'freerdp'      # RDP Connections
    'libvncserver' # VNC Connections
    'nautilus'     # Filesystem browser
    'remmina'      # Remote Connection
    'veracrypt'    # Disc encryption utility
    'variety'      # Wallpaper changer

    # DEVELOPMENT ---------------------------------------------------------
    \
    'ccache'   # Compiler cacher
    'clang'    # C Lang compiler
    'cmake'    # Cross-platform open-source make system
    'code'     # Visual Studio Code
    'electron' # Cross-platform development using Javascript
    'git'      # Version control system
    'gcc'      # C/C++ compiler
    'glibc'    # C libraries
    'meld'     # File/directory comparison
    'nodejs'   # Javascript runtime environment
    'npm'      # Node package manager
    'python'   # Scripting language
    'yarn'     # Dependency management (Hyper needs this)

    # MEDIA ---------------------------------------------------------------
    \
    'kdenlive'   # Movie Render
    'obs-studio' # Record your screen
    'celluloid'  # Video player

    # GRAPHICS AND DESIGN -------------------------------------------------
    \
    'gcolor2'   # Colorpicker
    'gimp'      # GNU Image Manipulation Program
    'ristretto' # Multi image viewer

    # PRODUCTIVITY --------------------------------------------------------
    \
    'xpdf' # PDF viewer

)

for PKG in "${PKGS[@]}"; do
    echo -e "INSTALLING: ${PKG}"
    sudo apt install -y "$PKG"
done

echo -e "Done!"

# ------------------------------------------------------------------------

echo -e "FINAL SETUP AND CONFIGURATION"

echo -e "Configuring vconsole.conf to set a larger font for login shell"
echo -e "FONT=ter-v32b" | sudo tee -a /etc/vconsole.conf

# ------------------------------------------------------------------------

echo -e "Increasing file watcher count"

# This prevents a "too many files" error in Visual Studio Code
echo -e fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.d/40-max-user-watches.conf &&
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

# Prevent stupid error beeps
sudo rmmod pcspkr
echo -e "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/nobeep.conf

# ------------------------------------------------------------------------

clear

echo -e "
###############################################################################
# All done! Would you also mind to run the author's ultra-gaming-setup-wizard?
###############################################################################
"

extra() {
    curl https://raw.githubusercontent.com/YurinDoctrine/ultra-gaming-setup-wizard/main/ultra-gaming-setup-wizard.sh >ultra-gaming-setup-wizard.sh &&
        chmod 755 ultra-gaming-setup-wizard.sh &&
        ./ultra-gaming-setup-wizard.sh
}

final() {
    read -p $'yes/no >_: ' ans
    if [[ "$ans" == "yes" ]]; then
        echo -e "RUNNING ..."
        extra
    elif [[ "$ans" == "no" ]]; then
        echo -e "LEAVING ..."
        exit 1
    else
        echo -e "INVALID VALUE!"
        final
    fi
}
final
