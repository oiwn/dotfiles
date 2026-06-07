{ pkgs, vars, ... }:

{
  # =====================
  # Git
  # =====================
  programs.git = {
    enable = true;
    settings = {
      user.name = vars.gitName;
      user.email = vars.gitEmail;
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
