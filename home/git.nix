{ primaryUser, ... }:
{
  programs.git = {
    enable = true;
    userName = "Khandker Mahmudur Rahman";
    userEmail = "mahmudur.rahman@fieldnation.com";

    signing = {
      key = "B87897B3E9596077";
      signByDefault = true;
    };

    lfs.enable = true;

    ignores = [ "**/.DS_STORE" "**/.serena" ];

    extraConfig = {
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
