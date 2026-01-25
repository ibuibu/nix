{ ... } : {
  programs.git = {
    enable = true;
    settings = {
      core = {
        editor = "nvim";
      };
      init = {
        defaultBranch = "main";
      };
      push = {
        default = "current";
      };
      user = {
        name = "ibuibu";
        email = "ibuibu69@gmail.com";
        signingkey = "~/.ssh/id_ed25519.pub";
      };
      gpg = {
        format = "ssh";
      };
      commit = {
        gpgsign = true;
      };
      tag = {
        gpgsign = true;
      };
    };
    ignores = [
      ".DS_Store"
      ".env"
    ];
  };
}
