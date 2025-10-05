{ config, pkgs, lib, ... }:

let
  screenshotDir = "${config.home.homeDirectory}/Pictures/Screenshots";
in {
  ########################################
  # Packages needed for this setup
  ########################################
  home.packages = with pkgs; [

    (pkgs.writeShellApplication {
      name = "set-wallpapers";
      runtimeInputs = [ pkgs.hyprpaper pkgs.jq pkgs.procps ];
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        WALL_ULTRA="''${1:-/etc/nixos/assets/appa_wallpaper_wide2.png}"
        WALL_OTHER="''${2:-/etc/nixos/assets/appa_wallpaper_UHD.png}"

        CFG="''${XDG_RUNTIME_DIR:-/tmp}/hyprpaper.auto.conf"
        : > "''${CFG}"

        echo "preload = ''${WALL_ULTRA}" >> "''${CFG}"
        echo "preload = ''${WALL_OTHER}" >> "''${CFG}"

        hyprctl -j monitors | jq -r '.[] | "\(.name) \(.width)x\(.height)"' | \
        while read -r name res; do
          if [[ "''${res}" == "5120x1440" ]]; then
            echo "wallpaper = ''${name},''${WALL_ULTRA}" >> "''${CFG}"
          else
            echo "wallpaper = ''${name},''${WALL_OTHER}" >> "''${CFG}"
          fi
        done

        # restart hyprpaper with the generated config
        pkill -x hyprpaper 2>/dev/null || true
        nohup hyprpaper -c "''${CFG}" >/dev/null 2>&1 &
      '';
    })

    waybar
    cava
    swaynotificationcenter
    python3
    fastfetch
    flameshot
    hyprpaper
    jq
  ];
  

  ########################################
  # Hyprland (window manager) settings
  ########################################
  home.sessionVariables.HYPRLAND_CONFIG = "$HOME/.config/hypr/hyprland.conf";

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {

      device = [
        {
          name = "asup1207:00-093a:3012-touchpad";  # must be first
          natural_scroll = true;
        }
      ];

      # --- your existing binds (kept) ---
      bind = [
        # swap
        "SUPER SHIFT, L, swapwindow, r"
        "SUPER SHIFT, H, swapwindow, l"
        "SUPER SHIFT, K, swapwindow, u"
        "SUPER SHIFT, J, swapwindow, d"

        # focus
        "SUPER, left,  movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up,    movefocus, u"
        "SUPER, down,  movefocus, d"

        # nudge floating
        "binde = SUPER ALT, H, moveactive, -30 0"
        "binde = SUPER ALT, L, moveactive,  30 0"
        "binde = SUPER ALT, K, moveactive,  0  -30"
        "binde = SUPER ALT, J, moveactive,  0   30"

        # Workspace binds
        # Cycle through workspaces
        "bind = SUPER_CTRL, left,  workspace, -1"
        "bind = SUPER_CTRL, right, workspace, +1"

        # Hold SUPER and right-click drag to resize
        "bindm = SUPER, mouse:272, movewindow"   # left click drag moves

        "bind = SUPER_ALT, h, resizeactive, -20 0"
        "bind = SUPER_ALT, l, resizeactive, 20 0"
        "bind = SUPER_ALT, k, resizeactive, 0 -20"
        "bind = SUPER_ALT, j, resizeactive, 0 20"

        # screenshots
        "SUPER, Delete, exec, flameshot gui"
       
        # Utilities
        "SUPER, Return, exec, alacritty"
        "SUPER, D, exec, rofi -show drun"
     
        "SUPER, Q, killactive"  
      ];

      gesture = [
        "3, horizontal, workspace"
      ];
      # --- nice defaults (kept, with accent borders) ---
      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        layout = "dwindle";
        "col.inactive_border" = "rgb(ff9999)";
        "col.active_border" = "rgb(ff4c4c)";
      };

      decoration = {
        rounding = 12;
        active_opacity = 0.97;
        inactive_opacity = 0.92;
      };

      animations = {
        enabled = true;
        bezier = "ease, 0.15, 0.9, 0.1, 1.0";
        animation = [
          "windows, 1, 5, ease"
          "border,  1, 10, ease"
          "fade,    1, 5, ease"
          "workspaces, 1, 6, ease"
        ];
      };

      # --- autostart: notifications, cava fifo, waybar ---
      exec-once = [
        "systemctl --user start swaync.service"
        "bash -lc 'mkdir -p ~/.cache/visualizer && rm -f ~/.cache/visualizer/cava.fifo && mkfifo ~/.cache/visualizer/cava.fifo'"
        "cava -p ~/.config/cava/config &"
        "waybar"
        "set-wallpapers"
      ];
    };
  };

  ########################################
  # Waybar (top bar) – themed pills & modules
  ########################################
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;
        margin-top = 8;
        margin-left = 16;
        margin-right = 16;
        spacing = 8;
        reload_style_on_change = true;

        "modules-left" = [ "image#logo" ];
        "modules-center" = [ "custom/visualizer" "clock" ];
        "modules-right" = [ "custom/swaync" "network" "cpu" ];

        # Left: Hyprland logo (we’ll ship an SVG below)
        "image#logo" = {
          path = "${config.home.homeDirectory}/.config/waybar/icons/hyprland.svg";
          size = 22;
          tooltip = false;
        };

        # Center: Cava-based visualizer + clock
        "custom/visualizer" = {
          exec = "~/.config/waybar/scripts/visualizer.py";
          return-type = "json";
          interval = 0.05;
          restart-interval = 0;
          tooltip = false;
        };

        clock = {
          format = "{:%a %b %d  %I:%M %p}";
          tooltip = true;
          "tooltip-format" = "{:%A, %B %d, %Y}";
        };

        # Right: notifications (swaync), network, CPU
        "custom/swaync" = {
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          interval = 1;
        };

        network = {
          "format" = "{ifname}";
          "format-wifi" = " {signalStrength}%";
          "format-ethernet" = "󰈀 {ifname}";
          "format-disconnected" = "󰖪";
          "tooltip-format" = "{ifname} ({ipaddr})\nUp: {bandwidthUpBits}\nDown: {bandwidthDownBits}";
          interval = 2;
        };

        cpu = {
          format = " {usage}%";
          interval = 2;
          tooltip = true;
        };
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", Inter, sans-serif;
        font-size: 12.5pt;
      }
      @define-color bg rgba(0,0,0,0.55);
      @define-color bg-dim rgba(20,20,20,0.55);
      @define-color fg #eeeeee;
      @define-color accent #ff7a90; /* pastel red */
      @define-color border rgba(255,122,144,0.7);

      window#waybar {
        background: transparent; /* no full-width slab */
        color: @fg;
      }

      .modules-left, .modules-center, .modules-right {
        background: @bg;
        padding: 6px 10px;
        border-radius: 14px;            /* rounded “pills” */
        box-shadow: 0 8px 24px rgba(0,0,0,0.35);
        border: 1px solid @border;
      }

      /* center pill slightly different tint */
      .modules-center { background: @bg-dim; }

      #custom-visualizer, #clock, #cpu, #network, #custom-swaync, #image.logo {
        margin: 0 8px;
      }

      #image.logo { min-width: 28px; }

      #custom-visualizer {
        color: @accent;
        font-weight: 600;
        letter-spacing: 0.5px;
        margin-right: 14px;
      }

      #clock { opacity: 0.95; }

      #cpu:hover, #network:hover, #custom-swaync:hover { color: @accent; }

      #custom-swaync {
        padding: 0 6px;
        border-radius: 10px;
        background: rgba(255,122,144,0.12);
        border: 1px solid rgba(255,122,144,0.25);
      }

      /* subtle separators inside each pill */
      .modules-center > widget:not(:last-child),
      .modules-right > widget:not(:last-child) {
        border-right: 1px dashed rgba(255,122,144,0.25);
        margin-right: 10px;
        padding-right: 10px;
      }
    '';
  };

  ########################################
  # Notifications (SwayNC)
  ########################################
  services.swaync.enable = true;

  ########################################
  # Cava config + Waybar visualizer script
  ########################################
  home.file.".config/cava/config".text = ''
    [general]
    bars = 30
    framerate = 60
    autosens = 1
    overshoot = 20
    noise_reduction = 77

    [input]
    method = pulse
    source = auto

    [output]
    method = raw
    raw_target = ~/.cache/visualizer/cava.fifo
    data_format = ascii
    channels = mono
    autobars = 0
    use_utf8 = 1

    [color]
    foreground = #ff7a90
    background = #000000

    [smoothing]
    integral = 70
    monstercat = 1
    waves = 0
    gravity = 90
  '';

  home.file.".config/waybar/scripts/visualizer.py" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import os, json, time, select

      fifo = os.path.expanduser("~/.cache/visualizer/cava.fifo")
      bars = 30
      chars = " ▁▂▃▄▅▆▇█"

      def render_line(line):
          line = line.strip()
          if not line:
              return ""
          try:
              vals = [int(v) for v in line.split()]
          except ValueError:
              return ""
          out = []
          for v in vals[:bars]:
              idx = min(int((v / 100) * (len(chars) - 1)), len(chars) - 1)
              out.append(chars[idx])
          return "".join(out)

      def open_fifo(path):
          fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
          return fd

      while True:
          try:
              if not os.path.exists(fifo):
                  time.sleep(0.2)
                  continue
              fd = open_fifo(fifo)
              with os.fdopen(fd, 'r', buffering=1) as f:
                  while True:
                      rlist, _, _ = select.select([f], [], [], 1.0)
                      if not rlist:
                          print(json.dumps({"text":"", "class":"viz"}), flush=True)
                          continue
                      line = f.readline()
                      if not line:
                          break
                      text = render_line(line)
                      print(json.dumps({"text": text, "class":"viz"}), flush=True)
          except Exception:
              time.sleep(0.5)
    '';
  };

  # Ship a simple Hyprland logo SVG for Waybar
  home.file.".config/waybar/icons/hyprland.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
      <rect width="256" height="256" rx="48" fill="#000000"/>
      <path d="M48 176l56-96h48l56 96h-40l-40-72-40 72H48z" fill="#ff7a90"/>
    </svg>
  '';

  ########################################
  # Ensure directories exist
  ########################################
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  home.activation.createScreenshotDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${screenshotDir}"
  '';


  ########################################
  # VSCode
  ########################################
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;   # Microsoft build
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      ms-python.python
      ms-toolsai.jupyter
      ms-vscode.cpptools
    ];
    userSettings = {
      "editor.formatOnSave" = true;
    };
  };

  ########################################
  # Alacritty customizations
  ########################################
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = { x = 8; y = 8; };
        opacity = 0.95;
      };

      cursor = {
        style = "Beam";
        unfocused_hollow = true;
      };

      font = {
        normal = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
        bold   = { family = "JetBrainsMono Nerd Font"; style = "Bold"; };
        italic = { family = "JetBrainsMono Nerd Font"; style = "Italic"; };
        size = 11.0;
      };

      colors = {
        primary = {
          background = "0x0b0c0f";
          foreground = "0xEAEAEA";
        };
        cursor = {
          text   = "0x0b0c0f";
          cursor = "0xE57474";
        };
        selection = {
          text = "0xEAEAEA";
          background = "0x1a1b20";
        };
        normal = {
          black   = "0x101217";
          red     = "0xE57474";
          green   = "0x8BD49C";
          yellow  = "0xE5C76B";
          blue    = "0x6CB6EB";
          magenta = "0xC47FD5";
          cyan    = "0x70C0BA";
          white   = "0xD0D0D0";
        };
        bright = {
          black   = "0x3b3f4c";
          red     = "0xF08A8A";
          green   = "0x9CE0AD";
          yellow  = "0xF0D88C";
          blue    = "0x82C7F4";
          magenta = "0xD4A1E6";
          cyan    = "0x8AD7CF";
          white   = "0xFFFFFF";
        };
      };

      bell = {
        animation = "EaseOutCubic";
        duration = 120;
        color = "0xE57474"; 
      };
    };
  };
  

  ########################################
  # Fastfetch customization
  ########################################

  xdg.configFile."fastfetch/config.jsonc".text = ''
  {
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",

    // Palette (for reference):
    // accent pastel red  #E57474 -> 229,116,116
    // bright red         #FF4C4C -> 255,76,76
    // light red          #FF9999 -> 255,153,153
    // foreground         #EAEAEA -> 234,234,234
    // dim gray           #3B3F4C -> 59,63,76

    "logo": {
      "type": "auto",
      "padding": { "top": 0, "left": 2, "right": 0, "bottom": 0 },
      // Some versions require numeric keys "1".."9" each mapping to a color OBJECT
      "color": {
        "1": { "r": 229, "g": 116, "b": 116 }   // accent pastel red
      }
    },

    "display": {
      "separator": "  ",
      // In this schema, colors are OBJECTS, not strings
      "color": {
        "keys":  { "r": 229, "g": 116, "b": 116 }, // key labels = pastel red
        "title": { "r": 234, "g": 234, "b": 234 }  // title = light foreground
      },
      "key": { "width": 12, "type": "string" }
    },

    "modules": [
      { "type": "title", "key": "", "color": { "r": 234, "g": 234, "b": 234 } },

      { "type": "os",        "key": "OS",      "keyColor": { "r": 229, "g": 116, "b": 116 } },
      { "type": "host",      "key": "Host",    "keyColor": { "r": 229, "g": 116, "b": 116 } },
      { "type": "kernel",    "key": "Kernel",  "keyColor": { "r": 229, "g": 116, "b": 116 } },
      { "type": "uptime",    "key": "Uptime",  "keyColor": { "r": 229, "g": 116, "b": 116 } },
      { "type": "packages",  "key": "Pkgs",    "keyColor": { "r": 229, "g": 116, "b": 116 } },
      { "type": "shell",     "key": "Shell",   "keyColor": { "r": 229, "g": 116, "b": 116 } },
      { "type": "wm",        "key": "WM",      "keyColor": { "r": 229, "g": 116, "b": 116 } },
      { "type": "terminal",  "key": "Term",    "keyColor": { "r": 229, "g": 116, "b": 116 } },

      { "type": "cpu",       "key": "CPU",     "keyColor": { "r": 229, "g": 116, "b": 116 } },
      { "type": "gpu",       "key": "GPU",     "keyColor": { "r": 229, "g": 116, "b": 116 } },
      { "type": "memory",    "key": "Memory",  "keyColor": { "r": 229, "g": 116, "b": 116 } },
      { "type": "disk",      "key": "Disk",    "keyColor": { "r": 229, "g": 116, "b": 116 }, "folders": [ "/" ] },
      { "type": "netio",     "key": "Net",     "keyColor": { "r": 229, "g": 116, "b": 116 } }
    ]
  }
  '';

  ########################################
  # Bash init (kept, with fastfetch)
  ########################################
  programs.bash = {
    enable = true;
    initExtra = ''
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
      export PATH="$HOME/.npm-global/bin:$PATH"
      if command -v fastfetch &>/dev/null; then
        fastfetch
      fi
    '';
  };
}
