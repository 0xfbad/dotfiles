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
        # cudaSupport only adds autoAddDriverRunpath so the nvml dlopen resolves
        package = pkgs.btop.override { cudaSupport = true; };
        # fails loudly instead of silently rendering #1e1e2e if upstream moves the line
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
          # rapl needs root, row hidden unless the binary has cap_perfmon and cap_dac_read_search
          show_cpu_watts = true;
        };
      };
    };
}
