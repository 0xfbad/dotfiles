_: {
  flake.modules.homeManager.btop =
    { pkgs, ... }:
    {
      catppuccin.btop.enable = true;

      programs.btop = {
        enable = true;
        # cudaSupport just makes the nvml dlopen resolve
        package = pkgs.btop-cuda;
        settings = {
          theme_background = false; # the terminal supplies the oled black
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
