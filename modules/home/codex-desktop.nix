{ inputs, ... }: {
  flake.modules.homeManager.codex-desktop = { pkgs, ... }: {
    imports = [
      inputs.codex-desktop-linux.homeManagerModules.default
    ];

    programs.codexDesktopLinux = {
      enable = true;
      # CODEX_CLI_PATH into launcher so it finds it without a session PATH
      cliPackage = pkgs.codex;
    };
  };
}
