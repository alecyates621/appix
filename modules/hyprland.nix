{ pkgs, ... }:
{
  programs.hyprland.enable = true;

  # Example: place config in /etc/xdg so both hosts share it; or use HM to manage per-user config
  environment.etc."xdg/hypr/hyprland.conf".text = ''
    monitor=,preferred,auto,1

    # Mod
    $mod = SUPER

    # Focus & sanity
    bind = $mod, left,  movefocus, l
    bind = $mod, right, movefocus, r
    bind = $mod, up,    movefocus, u
    bind = $mod, down,  movefocus, d

    # Resize (repeat while held) — Hyprland expects dispatcher, args
    binde = $mod, H, resizeactive, -30 0
    binde = $mod, L, resizeactive,  30 0
    binde = $mod, K, resizeactive,  0 -30
    binde = $mod, J, resizeactive,  0  30

    # Move inside layout (reorder)
    bind = $mod CTRL, H, movewindow, l
    bind = $mod CTRL, L, movewindow, r
    bind = $mod CTRL, K, movewindow, u
    bind = $mod CTRL, J, movewindow, d

    # Swap
    bind = $mod SHIFT, H, swapwindow, l
    bind = $mod SHIFT, L, swapwindow, r
    bind = $mod SHIFT, K, swapwindow, u
    bind = $mod SHIFT, J, swapwindow, d

    # Toggle floating + nudge when floating
    bind  = $mod,    F, togglefloating
    binde = $mod ALT, H, moveactive, -30 0
    binde = $mod ALT, L, moveactive,  30 0
    binde = $mod ALT, K, moveactive,  0 -30
    binde = $mod ALT, J, moveactive,  0  30


    # Save region → file
    bind = , Print, exec, grimblast --notify save area "$HOME/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png"

    # Copy region → clipboard
    bind = SUPER, Print, exec, grimblast --notify copy area
 
    # Save current window
    bind = CTRL, Print, exec, grimblast --notify save active "$HOME/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png"

    # (Optional) Region, then annotate in swappy
    bind = ALT, Print, exec, grimblast save area - | swappy -f -


    # Exit / reload
    bind = $mod SHIFT, E, exec, hyprctl dispatch exit
    bind = $mod, R, exec, hyprctl reload
  '';
}
