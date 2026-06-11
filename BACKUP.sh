#!/bin/bash
# Override the standard echo command globally
echo() {
    builtin echo -e "\033[7m >>> $* <<< \033[0m"
}
pacman_packages=( 'vivaldi' 'firefox' 'evince' 'meld' 'kdeconnect' 'thunar' 'foliate' 'okular' 'libreoffice-fresh' 'eog' 'virt-manager' 'gpu-screen-recorder' 'gwenview' 'copyq' 'lxappearance' 'helvum' 'rofi' 'hyprland' 'hyprpaper' 'hyprlock' 'waybar' 'dunst' 'wl-clipboard' 'dbus' 'wireplumber' 'brightnessctl' 'networkmanager' 'jq' 'grim' 'slurp' 'libnotify' 'xdg-user-dirs' 'alsa-utils' 'fastfetch' 'ffmpeg' 'flatpak' 'imagemagick' 'cups' 'system-config-printer' 'calc' 'btop' 'mpd' 'mpc' 'mpv' 'wev' 'rsync' 'cava' 'taskwarrior-tui' 'kitty' 'dua-cli' 'img2pdf' 'pastel' 'swappy' 'syncthing' 'tesseract-data-eng' 'tesseract' 'synaptics' 'tree-sitter' 'ufw' 'vlc' 'trash-cli' 'fd' 'ripgrep' 'fzf' 'zoxide' 'poppler' 'perl-image-exiftool' 'yazi' 'micro' 'bluez' 'net-tools' 'bc' '7zip' 'pavucontrol' 'docker' 'tailscale' 'tlp' 'neovim' 'pipewire-pulse' 'task' 'starship' 'eza' 'bat' 'thefuck' 'tealdeer' 'croc' 'xorg-xrdb' )
aur_packages=( 'brother-mfc-l2740dw' 'hyprkcs-git' 'waynergy' 'auto-cpufreq' 'peaclock' 'libinput-gestures' 'pacfetch' 'python-jpegtran-cffi-git' 'fbida' 'rmpc-git' 'tree-sitter-latex' 'tree-sitter-yaml' 'tree-sitter-markdown' )
flatpak_packages=( 'com.oppzippy.OpenSCQ30' 'org.gnome.gitlab.YaLTeR.Identity' 'org.gnome.Characters' 'org.kde.kruler')
brew_packages=( 'grex' 'asciinema' 'stylua' 'prettier' 'fancy-cat' 'lm_sensors' 'unzip' )
system_services=( 'cups.path' 'auto-cpufreq.service' 'avahi-daemon.service' 'bluetooth.service' 'cups.service' 'docker.service' 'libvirtd.service' 'NetworkManager-dispatcher.service' 'NetworkManager-wait-online.service' 'NetworkManager.service' 'sshd.service' 'systemd-resolved.service' 'systemd-timesyncd.service' 'tailscaled.service' 'tlp.service' 'ufw.service' 'avahi-daemon.socket' 'cups.socket' 'libvirtd-admin.socket' 'libvirtd-ro.socket' 'libvirtd.socket' 'systemd-resolved-monitor.socket' 'systemd-resolved-varlink.socket' 'systemd-userdbd.socket' 'virtlockd-admin.socket' 'virtlockd.socket' 'virtlogd-admin.socket' 'virtlogd.socket' 'remote-fs.target' 'fstrim.timer')
user_services=( 'mpd.service' 'syncthing.service' 'wireplumber.service' 'xdg-user-dirs.service' 'p11-kit-server.socket' 'pipewire-pulse.socket' 'pipewire.socket' 'pipewire-pulse.service' ) 
groups=('lp' 'docker' 'libvirt')
echo "starting setup..."
cd ~ || exit
echo "Updating system"
sudo pacman -Syu
# Get my current .bashrc so everything which is needed is already there.
curl https://raw.githubusercontent.com/MrSavageBanana/MyDotFiles/refs/heads/main/.bashrc > ~/.bashrc

read -s -n 1 -p "Press [Enter] to setup Yay and install packages, or any other key to skip: " key
echo ""

if [ -z "$key" ]; then
    echo "Running the action..."
    echo "Installing Yay"
    echo "Installing Yay Dependencies"
    sudo pacman -S --needed git base-devel go 
    echo "Cloning Yay Repo"
    git clone https://aur.archlinux.org/yay.git
    echo "Compiling Yay"
    cd yay && makepkg -si
    if command -v yay; then
	    echo "Installing All AUR Packages"
	    yay -S "${aur_packages[@]}"
    else
	    echo "INSTALL AUR PACKAGES YOURSELF"
    fi
else
    echo "Skipped. Continuing with the rest of the script..."
fi

# Rest of your script goes here
echo "Going to HOME"
cd ~
echo "Installing All Pacman Packages"
# for loop created with Claude. Account: Milobowler
for attempt in 1 2 3; do
    sudo pacman -S --needed "${pacman_packages[@]}" && break
    echo "Pacman failed (attempt $attempt/3)"
    [[ $attempt -lt 3 ]] && sleep 5
done
if command -v xdg-user-dirs-update; then
	echo "CREATING FOLDER STRUCTURE"
	xdg-user-dirs-update
	cd ~
	rmdir ~/Desktop
	echo "REMOVED DESKTOP FOLDER"
	mkdir -p  ~/Downloads/Code/
	echo "CREATED CODE FOLDER"
	mkdir ~/Music_new
	echo "CREATED MUSIC FOLDER"
	mkdir -p ~/Downloads/Git_Cloned/
	echo "CREATED GIT_CLONED FOLDER"
	mv ~/yay ~/Downloads/Git_Cloned
else 
	echo "RUN xdg-user-dirs-update YOURSELF"
fi
# The if statements replaces these three:
#echo "xdg-user-dirs-update"
#xdg-user-dirs-update 
#rmdir Desktop
# I need to download rust before the yay packages because they always ask me about rust or rustup and it screws up the rest so this can hopefull fix it
read -s -n 1 -p "Press [Enter] to setup rust, or any other key to skip: " key
echo ""

if [ -z "$key" ]; then
	echo "Running the action..."
	# Put the command you want to run right here
	echo "Installing Rustup MANUALLY"
	curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh 
	echo "ENDED RUSTUP MANUALLY"
else
    echo "Skipped. Continuing with the rest of the script..."
fi


echo "Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

if command -v brew; then
	read -s -n 1 -p "Press [Enter] to install All brew packages, or any other key to install needed packages: " key
	echo ""

	if [ -z "$key" ]; then
		echo "Installing All Homebrew Packages"
		brew install "${brew_packages[@]}"
	else
		echo "Installing needed Packages"
		brew install "${brew_packages[4]}"
	fi
else 
	echo "INSTALL BREW PACKAGES YOURSELF"
fi


# Rest of your script goes here
echo "Script continues..."
# echo "Installing tailscale"
# curl -fsSL https://tailscale.com/install.sh | sh 
echo "installing atuin"
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
#echo "Installing starship"
#curl -sS https://starship.rs/install.sh | sh 
# SOMETHING IS FUCKED
# flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flatpaks  there is no evidence this needs to be run. 
read -s -n 1 -p "Press [Enter] to setup flatpak, or any other key to skip: " key
echo ""

if [ -z "$key" ]; then
	echo "ATTEMPTING FLATPAK INSTALL"
	if command -v flatpak; then
		sleep 2 # maybe this can stop the random answer of "n" when flatpak asks to install stuff 
		echo "Installing All Flatpak Packages"
		flatpak install flathub "${flatpak_packages[@]}"
	else
		echo "INSTALL FLATPAK PACKAGES YOURSELF"
	fi
else
    echo "Skipped. Continuing with the rest of the script..."
fi

if command -v starship; then
	starship init bash > ~/.starship_static_init.sh
else
	echo "RUN starship init bash > ~/.starship_static_init.sh YOURSELF"
fi
if command -v fzf; then
	fzf --bash > ~/.fzf_static.bash
else
	echo "RUN fzf --bash > ~/.fzf_static.bash YOURSELF"
fi
echo "Installing Dotfiles"
git clone https://github.com/MrSavageBanana/MyDotFiles.git 
if [ -d "MyDotFiles" ] ; then
	echo "applying dotfiles"
	cd 'MyDotFiles' || exit
	cp -r dunst ~/.config/dunst
	cp -r hypr ~/.config/hypr
	cp -r kitty ~/.config/kitty
	cp -r micro ~/.config/micro
	cp -r mpd ~/.config/mpd
	cp -r nvim ~/.config/nvim
	cp -r rmpc ~/.config/rmpc
	cp -r rofi ~/.config/rofi
	cp -r waybar ~/.config/waybar
	chmod +x ~/.config/waybar/scripts/privacy_dots.sh
	cp -r yazi ~/.config/yazi
	cp starship.toml ~/.config
	cp starship-tty.toml ~/.config
	if [[ -d "$HOME/.config/atuin" ]]; then
		rm "$HOME/.config/atuin/config.toml"
		cp atuin/config.toml ~/.config/atuin
	else 
		echo "ATUIN WASN'T INSTALLED"
	fi
	cp .bash-preexec.sh ~
	cp .dircolors_cache ~
	if command -v zoxide; then
		zoxide init bash > ~/.zoxide-init.bash
	fi
	mkdir ~/.mydotfiles
	cp sync_dots.sh  ~/.mydotfiles/
	cp -r VivaldiCSS ~/Downloads/VivaldiCSS
	if command -v python3; then
		echo "installing pywal"
		echo "creating virtual environment"
		python3 -m venv .wal
		if [[ -d ".wal" ]]; then
			echo "entering environment"
			source .wal/bin/activate 
			pip install nu-pywal
		fi
		if [[ -e ".wal/bin/wal" ]]; then
			echo "applying pywal"
			wal -i ~/MyDotFiles/wallpapers/greyscaled.jpg
			deactivate
		fi
	fi
	echo "Installing Fonts"
	cd ~/MyDotFiles/u/s/
	sudo cp * /usr/share/fonts
	cd ~/MyDotFiles/l/s/fonts/
	mkdir -p "$HOME/.local/share/fonts"
	sudo cp * ~/.local/share/fonts
	cd ~
	fc-cache -fv
	mkdir -p "$HOME/.local/bin"
	if [[ -d "$HOME/.local/bin" ]]; then
		echo "Copying ~/.local/bin files"
		cd /home/shayan/MyDotFiles/local
		cp * ~/.local/bin
		chmod +x ~/.local/bin/rofi-run-wrapper.sh
	else
		echo "Copying Local files (somehow) didn't work"
	fi
fi
echo "Editing .desktop files"
cd /usr/share/applications
RemoveFromRofiResults=( 'nvim.desktop' 'mpv.desktop' 'micro.desktop' 'vivaldi-stable.desktop' 'btop.desktop' 'kitty.desktop' 'rofi.desktop' 'yazi.desktop')
for results in "${RemoveFromRofiResults[@]}"; do
	if [[ -e $results ]]; then
		sudo mv "$results" "$results.bak"
	else 
		echo "$results doesn't exist so won't be renamed"
	fi
done
cd ~ || true
echo "Enabling Services"
systemctl --user enable --now "${user_services[@]}"
sudo systemctl enable --now "${system_services[@]}"
echo "Adding shayan to groups"
for service in "${groups[@]}"; do
	sudo usermod -aG "$service" shayan
done
echo "AUTHENTICATE TAILSCALE YOURSELF"
echo "Finished. run source ~/.bashrc. "
#atuin init bash --disable-ctrl-r --disable-up-arrow > ~/.atuin_static_init.sh && sed -i 's/ATUIN_SESSION=$(atuin uuid)/ATUIN_SESSION=$(cat \/proc\/sys\/kernel\/random\/uuid)/' ~/.atuin_static_init.sh
echo "run: line 158"
# Directories touched
# /usr/share/applications
# 	nvim.desktop.bak
# 	mpv.desktop.bak
# 	micro.desktop.bak
# 	vivaldi-stable.desktop.bak
# 	kitty.desktop.bak
# 	micro.desktop.bak
# 	btop.desktop.bak
# 	rofi.desktop.bak
# 	yazi.desktop.bak
# ~/.local/bin
# 	hotspot
# 	rofi-run-wrapper.sh
# 	treecatotal
# 	vivaldi-custom
# 	VM
# 	VP
# ~/Downloads
# 	Git_Cloned/yay
# 	Code
# 	VivaldiCSS
# ~/
# 	.atuin_static_init.sh
# 	.bash-preexec.sh
# 	.dircolors_cache
# 	.fzf_static.bash
### 	.starship_static_init.sh 
# 	.zoxide-init.bash
# 	.mydotfiles/sync_dots.sh
# 	~/Music_new/
# ~/.config
# 	starship.toml
# 	starship-tty.toml
# 	/atuin/config.toml
# 	yazi/
# 	waybar/
# 	rofi/
# 	rmpc/
# 	nvim/
# 	mpd/
# 	micro/
# 	kitty/
# 	hypr/
# 	dunst/
# /usr/share/fonts
# 	fonts
# ~/.local/share/fonts/
# 	fonts
# 
