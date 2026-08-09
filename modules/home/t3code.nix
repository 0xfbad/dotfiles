_: {
  flake.modules.homeManager.t3code =
    {
      config,
      pkgs,
      ...
    }:
    {
      # electron app checks for updates it can never install from the store
      home.sessionVariables.T3CODE_DISABLE_AUTO_UPDATE = "1";

      programs.t3code = {
        enable = true;
        package = pkgs.t3code.override {
          enableClaude = true;
          # keep the bundled claude on the same build programs.claude-code manages
          claude-code = config.programs.claude-code.finalPackage;
          enableCodex = false;
          enableJujutsu = true;
          enableOpencode = true;
        };
        # codex defaults on in the settings schema, the binary would be advertised but missing
        userSettings.providers.codex.enabled = false;
      };
    };
}
