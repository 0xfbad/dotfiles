_: {
  flake.homeModules.starship = _: {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        character = {
          success_symbol = "[\\$](bold green)";
          error_symbol = "[\\$](bold red)";
        };
      };
    };
  };
}
