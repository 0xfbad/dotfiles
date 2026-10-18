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
          # TODO: temp until nixpkgs#569702 merged
          t3code-unwrapped = pkgs.t3code.unwrapped.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.patchelf ];
            postFixup = (old.postFixup or "") + ''
              for module in "$out"/libexec/t3code/node_modules/.pnpm/node-pty@*/node_modules/node-pty/prebuilds/linux-${pkgs.stdenv.hostPlatform.node.arch}/pty.node; do
                patchelf --add-rpath ${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]} "$module"
              done
            '';
          });
        };
      };
    };
}
