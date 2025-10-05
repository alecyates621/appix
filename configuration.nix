# This is only here for legacy tools.
# All real configuration lives in the flake at /etc/nixos.

{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Just enough to boot + tell you to use flakes
  system.stateVersion = "24.05"; # or whatever matches your install
}
