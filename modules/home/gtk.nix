_: {
  flake.homeModules.gtk = {pkgs, ...}: {
    gtk = {
      enable = true;
      theme = {
        name = "catppuccin-mocha-mauve-standard+default";
        package = pkgs.catppuccin-gtk.override {
          accents = ["mauve"];
          variant = "mocha";
        };
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = "mocha";
          accent = "mauve";
        };
      };
    };

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
