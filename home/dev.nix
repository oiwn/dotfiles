{ pkgs, vars, ... }:

{
  # =====================
  # Git
  # =====================
  programs.git = {
    enable = true;
    userName = vars.gitName;
    userEmail = vars.gitEmail;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # =====================
  # GitHub CLI
  # =====================
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };

  # =====================
  # GPG
  # =====================
  programs.gpg.enable = true;
}
