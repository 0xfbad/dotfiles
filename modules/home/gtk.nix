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

    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style.name = "kvantum";
    };

    xdg.configFile = {
      "Kvantum/kvantum.kvconfig".text = ''
        [General]
        theme=catppuccin-mocha-mauve
      '';
      "Kvantum/catppuccin-mocha-mauve".source = "${
        pkgs.catppuccin-kvantum.override {
          variant = "mocha";
          accent = "mauve";
        }
      }/share/Kvantum/catppuccin-mocha-mauve";
    };

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
