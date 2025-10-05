{ config, pkgs, lib, ... }:
{
  networking.hostName = lib.mkDefault "nixos";  # overridden by per-host config
  time.timeZone = "America/Chicago";

  users.users.appa = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "input" "networkmanager" ];
  };

  programs.ssh.startAgent = true;
  services.openssh.enable = true;

  # New name: use graphics.enable (replaces old opengl.enable)
  hardware.graphics.enable = true;

  # XWayland bits for apps that need it + polkit
  services.xserver.enable = true;
  security.polkit.enable = true;

  # PipeWire (audio)
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    jack.enable = true;
  };

  # ---------- Fonts & Theming ----------
  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-emoji
    ];
  };

  # Desktop portals for Wayland (include Hyprland portal)
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  # System-wide theme envs (apps can still override)
  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    GTK_THEME     = "Catppuccin-Mocha-Standard-Blue-Dark";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };

  # ---------- Packages ----------
  environment.systemPackages = with pkgs; [
    git curl wget vim
    # terminal
    alacritty
    # bar / launcher / notifications / wallpaper
    waybar
    rofi
    mako
    hyprpaper
    # themes
    catppuccin-gtk
    tela-icon-theme
    bibata-cursors
    flameshot
  ];

  # ---------- Config files dropped into /etc/xdg ----------
  # Waybar config (JSON) + CSS
  environment.etc."xdg/waybar/config".text = ''
    {
      "layer": "top",
      "position": "top",
      "height": 32,
      "modules-left": [ "hyprland/workspaces", "hyprland/window" ],
      "modules-center": [],
      "modules-right": [ "pulseaudio", "network", "battery", "clock" ],
      "clock": { "format": "{:%a %b %d  %H:%M}" },
      "battery": { "format": "{capacity}%" },
      "pulseaudio": { "format": "{volume}%" },
      "network": { "format-wifi": "{essid} ({signalStrength}%)" },
      "hyprland/window": { "max-length": 60 }
    }
  '';
  environment.etc."xdg/waybar/style.css".text = ''
    * { font-family: "JetBrainsMono Nerd Font", monospace; font-size: 12pt; }
    window#waybar {
      background: rgba(30,30,46,0.6);
      border: 1px solid #1e1e2e;
      border-radius: 16px;
      margin: 6px 10px;
    }
    #workspaces button { padding: 0 8px; color: #cdd6f4; }
    #workspaces button.active {
      background: rgba(137,180,250,0.18);
      color: #89b4fa; border-radius: 10px;
    }
    #clock, #battery, #pulseaudio, #network, #window {
      padding: 0 10px; color: #cdd6f4;
    }
    tooltip { background: #1e1e2e; color: #cdd6f4; border: 1px solid #313244; }
  '';

  # Rofi (Wayland) theme + config — rofi-wayland merged into rofi
  environment.etc."xdg/rofi/config.rasi".text = ''
    configuration {
      modi: "drun,run";
      show-icons: true;
      font: "JetBrainsMono Nerd Font 12";
      display-drun: "Apps";
      terminal: "alacritty";
    }
    @theme "catppuccin-mocha"
  '';
  environment.etc."xdg/rofi/themes/catppuccin-mocha.rasi".text = ''
    * {
      bg: #1e1e2e;
      bg-alt: #181825;
      fg: #cdd6f4;
      accent: #89b4fa;
      sel: #313244;
    }
    window { background-color: @bg; border: 2px; border-color: @sel; border-radius: 16px; }
    listview, element, inputbar, message, textbox-prompt-colon { background-color: transparent; }
    element.selected { background-color: @sel; }
    element-text { text-color: @fg; }
    element-icon { size: 1.2em; }
    inputbar { padding: 8px; border: 0px; }
  '';

  # Alacritty theme
  environment.etc."xdg/alacritty/alacritty.toml".text = ''
    [window]
    padding = { x = 10, y = 10 }
    opacity = 0.95

    [font]
    normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
    size = 12

    [colors.primary]
    background = "#1e1e2e"
    foreground = "#cdd6f4"

    [colors.normal]
    black   = "#45475a"
    red     = "#f38ba8"
    green   = "#a6e3a1"
    yellow  = "#f9e2af"
    blue    = "#89b4fa"
    magenta = "#cba6f7"
    cyan    = "#94e2d5"
    white   = "#bac2de"
  '';

  # hyprpaper config (wallpaper)
  environment.etc."xdg/hypr/hyprpaper.conf".text = ''
    preload = /home/appa/Pictures/wallpapers/wave.jpg
    wallpaper = ,/home/appa/Pictures/wallpapers/wave.jpg
    ipc = on
  '';

  # mako (notifications)
  environment.etc."xdg/mako/config".text = ''
    default-timeout=5000
    background-color=#1e1e2eD0
    text-color=#cdd6f4
    border-color=#313244
    border-radius=12
    border-size=2
    max-visible=5
    font=JetBrainsMono Nerd Font 12
  '';

  # Let your user install global npm CLIs under ~/.npm-global and have them on PATH
  environment.interactiveShellInit = ''
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export PATH="$HOME/.npm-global/bin:$PATH"
  '';


  # Flatpak optional (if you want it)
  # services.flatpak.enable = true;
}
