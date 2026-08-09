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
          # tracked binary asset, no formatter claims it
          excludes = [ "*.png" ];
          # case arms indented, shfmt flattens them otherwise
          formatter.shfmt.options = [ "-ci" ];
        };

        programs.deadnix.enable = true;

        programs.statix = {
          enable = true;
          # treefmt runs statix fix, repeated_keys has no autofix, the flat keys are deliberate
          disabled-lints = [ "repeated_keys" ];
        };

        # same libnixf engine nixd already runs in helix, on trial next to statix
        programs.nixf-diagnose.enable = true;

        # runs last so nix linter rewrites still get formatted
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
