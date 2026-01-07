{ pkgs, ... }:
{
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    # enableSshSupport = true;
    # sshKeys = [ "DD4E6C0077DC0801CC34214FCE7998BA338A88CA" ];
    pinentry.package = pkgs.pinentry_mac;
  };
}
