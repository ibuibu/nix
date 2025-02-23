{ ... } : {
  programs.git = {
    enable = true;
    extraConfig = {
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
      };
    };
    ignores = [
      ".DS_Store"
      ".env"
    ];
  };
}
