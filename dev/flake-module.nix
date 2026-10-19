{ inputs, ... }: {
  imports = [
    inputs.treefmt.flakeModule
  ];

  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      treefmt = {
        settings = {
          on-unmatched = "warn";
          excludes = [ "*.png" ];
          formatter.shfmt.options = [ "-ci" ];
        };

        programs.deadnix.enable = true;

        programs.statix = {
          enable = true;
          # flat keys are deliberate
          disabled-lints = [ "repeated_keys" ];
        };

        programs.nixf-diagnose.enable = true;

        # after the statix and deadnix rewrites
        programs.nixfmt = {
          enable = true;
          priority = 1;
        };

        programs.shfmt.enable = true;
        programs.shellcheck.enable = true;
        programs.keep-sorted.enable = true;
        programs.prettier.enable = true;

        programs.typos = {
          enable = true;
          configFile = "${./typos.toml}";
        };
      };

      devShells.default = pkgs.mkShell {
        inputsFrom = [ config.treefmt.build.devShell ];
      };
    };
}
