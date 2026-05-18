#!/bin/bash
# Override the standard echo command globally
echo() {
    builtin echo -e "\033[7m >>> $* <<< \033[0m"
}
run() {
    "$@" || echo "WARNING: command failed: $*"
}
pacman_packages=( 'vivaldi' 'firefox' 'evince' 'meld' 'kdeconnect' 'thunar' 'foliate' 'okular' 'libreoffice-fresh' 'eog' 'virt-manager' 'gpu-screen-recorder' 'gwenview' 'copyq' 'lxappearance' 'helvum' 'rofi' 'hyprland' 'hyprpaper' 'hyprlock' 'waybar' 'dunst' 'wl-clipboard' 'dbus' 'wireplumber' 'brightnessctl' 'networkmanager' 'jq' 'grim' 'slurp' 'libnotify' 'xdg-user-dirs' 'alsa-utils' 'fastfetch' 'ffmpeg' 'flatpak' 'imagemagick' 'cups' 'system-config-printer' 'calc' 'btop' 'rmpc' 'mpd' 'mpc' 'mpv' 'wev' 'rsync' 'cava' 'taskwarrior-tui' 'kitty' 'dua-cli' 'img2pdf' 'pastel' 'swappy' 'syncthing' 'tesseract-data-eng' 'tesseract' 'synaptics' 'tree-sitter' 'ufw' 'vlc' 'trash-cli' 'fd' 'ripgrep' 'fzf' 'zoxide' 'poppler' 'perl-image-exiftool' 'yazi' 'micro' 'bluez' 'net-tools' 'bc' '7zip' 'pavucontrol' 'docker' 'tailscale' 'tlp')
aur_packages=( 'brother-mfc-l2740dw' 'hyprkcs-git' 'waynergy' 'auto-cpufreq' 'peaclock' 'libinput-gestures' 'pacfetch' 'python-jpegtran-cffi-git' 'fbida')
flatpak_packages=( 'com.oppzippy.OpenSCQ30' 'org.gnome.gitlab.YaLTeR.Identity' 'org.gnome.Characters' 'org.kde.kruler')
brew_packages=('eza' 'bat' 'thefuck' 'tldr' 'grex' 'asciinema' 'stylua' 'prettier' 'tree-sitter-latex' 'tree-sitter-yaml' 'tree-sitter-markdown' 'fancy-cat' 'lm_sensors' 'starship' 'croc')
system_services=( 'cups.path' 'auto-cpufreq.service' 'avahi-daemon.service' 'bluetooth.service' 'cups.service' 'docker.service' 'libvirtd.service' 'NetworkManager-dispatcher.service' 'NetworkManager-wait-online.service' 'NetworkManager.service' 'sshd.service' 'systemd-resolved.service' 'systemd-timesyncd.service' 'tailscaled.service' 'tlp.service' 'ufw.service' 'avahi-daemon.socket' 'cups.socket' 'libvirtd-admin.socket' 'libvirtd-ro.socket' 'libvirtd.socket' 'systemd-resolved-monitor.socket' 'systemd-resolved-varlink.socket' 'systemd-userdbd.socket' 'virtlockd-admin.socket' 'virtlockd.socket' 'virtlogd-admin.socket' 'virtlogd.socket' 'remote-fs.target' 'fstrim.timer')
user_services=( 'mpd.service' 'syncthing.service' 'wireplumber.service' 'xdg-user-dirs.service' 'p11-kit-server.socket' 'pipewire-pulse.socket' 'pipewire.socket') 
groups=('lp' 'docker' 'libvirt')
echo "starting setup..."
cd ~
echo "Updating system"
sudo pacman -Syu
echo "Installing All Pacman Packages"
echo "Installing Yay"
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
cd ~
sudo pacman -S "${pacman_packages[@]}"
if command -v xdg-user-dirs-update; then
	xdg-user-dirs-update
	cd ~/Desktop
	rm *
	cd ~
	rmdir ~/Desktop
	mkdir -p  ~/Downloads/Code/
	mkdir ~/Music_new
	mkdir -p ~/Downloads/Git_Cloned/
	mv ~/yay ~/Downloads/Git_Cloned
else 
	echo "RUN xdg-user-dirs-update YOURSELF"
fi
# The if statements replaces these three:
#echo "xdg-user-dirs-update"
#xdg-user-dirs-update 
#rmdir Desktop
if command -v yay; then
	echo "Installing All AUR Packages"
	yay -S "${aur_packages[@]}"
else
	echo "INSTALL AUR PACKAGES YOURSELF"
fi

# flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flatpaks  there is no evidence this needs to be run. 
if command -v flatpak; then
	echo "Installing All Flatpak Packages"
	flatpak install flathub "${flatpak_packages[@]}"
else
	echo "INSTALL FLATPAK PACKAGES YOURSELF"
fi
echo "Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if command -v brew; then
	echo "Installing All Homebrew Packages"
	brew install "${brew_packages[@]}"
else 
	echo "INSTALL BREW PACKAGES YOURSELF"
fi
echo "Installing Rustup"
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh 
# echo "Installing tailscale"
# curl -fsSL https://tailscale.com/install.sh | sh 
if command -v tailscale; then
	sudo tailscale up
else
	echo "AUTHENTICATE TAILSCALE YOURSELF"
fi
echo "installing atuin"
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
#echo "Installing starship"
#curl -sS https://starship.rs/install.sh | sh 
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
	cd 'MyDotFiles' 
	cp -r dunst ~/.config/dunst
	cp -r hypr ~/.config/hypr
	cp -r kitty ~/.config/kitty
	cp -r micro ~/.config/micro
	cp -r mpd ~/.config/mpd
	cp -r nvim ~/.config/nvim
	cp -r rmpc ~/.config/rmpc
	cp -r rofi ~/.config/rofi
	cp -r waybar ~/.config/waybar
	cp -r yazi ~/.config/yazi
	cp starship.toml ~/.config
	cp starship-tty.toml ~/.config
	if [[ -d "~/.config/atuin" ]]; then
		cp atuin/config.toml ~/.config/atuin
	else 
		echo "ATUIN WASN'T INSTALLED"
	fi
	cp .bash-preexec.sh ~
	cp .dircolors_cache ~
	cp .bashrc ~
	if command -v zoxide; then
		zoxide init bash > ~/.zoxide-init.bash
	fi
	mkdir ~/.mydotfiles
	cp sync_dots.sh  ~/.mydotfiles/
	cp -r VivaldiCSS ~/Downloads/VivaldiCSS
	if command -v python3; then
		echo "installing pywal"
		python3 -m venv .wal
		if [[ -d ".wal" ]]; then
			source .wal/bin/activate 
			cd .wal/bin/activate 
			pip install nu-pywal
		fi
		if [[ -e ".wal/bin/wal" ]]; then
			echo "applying pywal"
			wal -i ~/MyDotFiles/Wallpapers/greyscaled.jpg
			deactivate
		fi
	fi
	echo "Installing Fonts"
	sudo cp -r ~/MyDotFiles/u/s/ /usr/share/fonts
	sudo cp -r ~/MyDotFiles/l/s/ ~/.local/share/fonts
	fc-cache -fv
	if [[ -d "~/.local/bin" ]]; then
		echo "Copying ~/.local/bin files"
		cd /home/shayan/MyDotFiles/local
		cp * ~/.local/bin
	else
		echo "Copying Local files didn't work"
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
echo "Finished. run ~/.bashrc. "
#atuin init bash --disable-ctrl-r --disable-up-arrow > ~/.atuin_static_init.sh && sed -i 's/ATUIN_SESSION=$(atuin uuid)/ATUIN_SESSION=$(cat \/proc\/sys\/kernel\/random\/uuid)/' ~/.atuin_static_init.sh
echo "run: line 158"
# Directories touched
# /usr/share/applications
# 	nvim.desktop.bak
# 	mpv.desktop.bak
# 	micro.desktop.bak
# 	vivaldi-stable.desktop.bak
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
# 	.starship_static_init.sh
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
