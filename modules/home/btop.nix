_: {
  flake.modules.homeManager.btop =
    {
      config,
      pkgs,
      ...
    }:
    let
      upstream = builtins.readFile "${config.catppuccin.sources.btop}/catppuccin_mocha.theme";
      oled =
        builtins.replaceStrings
          [ ''theme[main_bg]="#1e1e2e"'' ]
          [ ''theme[main_bg]="${config.colors.bg}"'' ]
          upstream;
    in
    {
      programs.btop = {
        enable = true;
        # cudaSupport just makes the nvml dlopen resolve
        package = pkgs.btop.override { cudaSupport = true; };
        themes.catppuccin_mocha =
          assert oled != upstream;
          oled;
        settings = {
          color_theme = "catppuccin_mocha";
          shown_boxes = "cpu mem net proc gpu0";
          shown_gpus = "nvidia";
          vim_keys = true;
          update_ms = 200;
          nvml_measure_pcie_speeds = false;
          save_config_on_exit = false;
          # needs the caps from the wrapper in common.nix
          show_cpu_watts = true;
        };
      };
    };
}
