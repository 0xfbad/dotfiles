_: {
  flake.homeModules.t3code = {pkgs, ...}: {
    programs.t3code = {
      enable = true;
      package = pkgs.t3code.override {
        enableClaude = true;
        enableOpencode = true;
      };
    };
  };
}
