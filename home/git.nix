{ primaryUser, pkgs, ... }:
{
  programs.gh = {
    enable = true;
  };

  programs.git = {
    enable = true;

    signing = {
      key = "B87897B3E9596077";
      signByDefault = true;
    };

    lfs.enable = true;

    ignores = [ "**/.DS_STORE" "**/.serena" ];

    settings = {
      user = {
        name = "Khandker Mahmudur Rahman";
        email = "mahmudur.rahman@fieldnation.com";
      };
      github = {
        user = "kmrfn";
      };
      push = {
        autoSetupRemote = true;
      };
      init = {
        defaultBranch = "main";
      };
    };
  };
}
