{ primaryUser, pkgs, ... }:
{
  programs.gh = {
    enable = true;
  };

  programs.git = {
    enable = true;

    # User identity lives in ~/.gitconfig (work) and ~/.gitconfig-personal (personal).
    signing.signByDefault = true;

    lfs.enable = true;

    ignores = [ "**/.DS_STORE" "**/.serena" ];

    settings = {
      push = {
        autoSetupRemote = true;
      };
      init = {
        defaultBranch = "main";
      };
    };
  };
}
