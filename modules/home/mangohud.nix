_: {
  flake.modules.homeManager.mangohud =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hex = lib.removePrefix "#";

      inherit (config) colors;
    in
    {
      programs.mangohud = {
        enable = true;
        settings = {
          cpu_temp = true;
          gpu_temp = true;
          ram = true;
          vram = true;
          vulkan_driver = true;
          wine = true;
          winesync = true;
          fps_metrics = [
            "avg"
            "0.01"
          ];
          throttling_status = true;
          # shows only when libgamemodeauto is mapped, set the game launch options to gamemoderun mangohud %command%
          gamemode = true;

          font_file = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";

          text_color = hex colors.text;
          text_outline_color = hex colors.surface0;
          gpu_color = hex colors.green;
          cpu_color = hex colors.blue;
          vram_color = hex colors.accent;
          ram_color = hex colors.pink;
          engine_color = hex colors.red;
          wine_color = hex colors.red;
          frametime_color = hex colors.green;
          network_color = hex colors.teal;
          background_color = hex colors.bg;
          background_alpha = 0.8;
          round_corners = colors.rounding;
        }
        # the igpu sits alongside the dgpu and 0.8.0 enumerates every card it finds
        // lib.optionalAttrs (osConfig.networking.hostName == "laptop") {
          pci_dev = "0000:01:00.0";
        };
      };
    };
}
