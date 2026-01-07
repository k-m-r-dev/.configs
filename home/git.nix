{ primaryUser, ... }:
{
  programs.git = {
    enable = true;
    userName = "Khandker Mahmudur Rahman";
    userEmail = "mahmudur.rahman@fieldnation.com";

    # signing = {
    #   key = "3832734CA36A92B9";
    #   signByDefault = true;
    # };

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
