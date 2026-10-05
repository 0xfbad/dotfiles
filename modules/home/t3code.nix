_: {
  flake.modules.homeManager.t3code =
    {
      config,
      pkgs,
      ...
    }:
    {
      home.sessionVariables.T3CODE_DISABLE_AUTO_UPDATE = "1"; # the updater cannot replace a package in the nix store

      programs.t3code = {
        enable = true;
        package = pkgs.t3code.override {
          enableClaude = true;
          claude-code = config.programs.claude-code.finalPackage;
          codex = config.programs.codex.package;
          enableJujutsu = true;
          enableOpencode = true;
        };
      };
    };
}
