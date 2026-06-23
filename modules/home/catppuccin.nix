{inputs, ...}: {
  flake.homeModules.catppuccin = _: {
    imports = [inputs.catppuccin.homeModules.catppuccin];

    # scoped opt-in only: gtk, qt/kvantum, icons and cursors are themed by hand
    # in gtk.nix, and waybar is self-themed from config.colors
    catppuccin = {
      flavor = "mocha";
      accent = "mauve";
      mako.enable = true;
    };
  };
}
