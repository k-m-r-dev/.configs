{ pkgs, ... }:
{
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    sshKeys = [ "89E76B4134EB1FFA7D50BDF0ABACF2A395F3C26D" ];
    pinentry.package = pkgs.pinentry_mac;
  };
}
