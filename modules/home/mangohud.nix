_: {
  flake.homeModules.mangohud = _: {
    programs.mangohud = {
      enable = true;
      settings = {
        fps = true;
        frametime = true;
        cpu_temp = true;
        gpu_temp = true;
        ram = true;
        vram = true;
        vulkan_driver = true;
        wine = true;
        gamemode = true;
      };
    };
  };
}
