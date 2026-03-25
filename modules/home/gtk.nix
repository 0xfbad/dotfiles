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
      platformTheme.name = "kde";
      style.name = "kvantum";
    };

    home.packages = with pkgs; [
      kdePackages.plasma-integration
      kdePackages.qqc2-desktop-style
      catppuccin-kde
    ];

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

      "kdeglobals".text = ''
        [General]
        ColorScheme=CatppuccinMochaMauve

        [KDE]
        widgetStyle=kvantum

        [Colors:View]
        BackgroundNormal=30,30,46
        BackgroundAlternate=36,36,54
        ForegroundNormal=205,214,244
        ForegroundInactive=166,173,200
        ForegroundActive=203,166,247
        ForegroundLink=137,180,250
        ForegroundVisited=203,166,247
        ForegroundNegative=243,139,168
        ForegroundNeutral=249,226,175
        ForegroundPositive=166,227,161
        DecorationFocus=203,166,247
        DecorationHover=203,166,247

        [Colors:Window]
        BackgroundNormal=24,24,37
        BackgroundAlternate=30,30,46
        ForegroundNormal=205,214,244
        ForegroundInactive=166,173,200
        ForegroundActive=203,166,247
        ForegroundLink=137,180,250
        ForegroundVisited=203,166,247
        ForegroundNegative=243,139,168
        ForegroundNeutral=249,226,175
        ForegroundPositive=166,227,161
        DecorationFocus=203,166,247
        DecorationHover=203,166,247

        [Colors:Button]
        BackgroundNormal=49,50,68
        BackgroundAlternate=69,71,90
        ForegroundNormal=205,214,244
        ForegroundInactive=166,173,200
        ForegroundActive=203,166,247
        ForegroundLink=137,180,250
        ForegroundVisited=203,166,247
        ForegroundNegative=243,139,168
        ForegroundNeutral=249,226,175
        ForegroundPositive=166,227,161
        DecorationFocus=203,166,247
        DecorationHover=203,166,247

        [Colors:Selection]
        BackgroundNormal=203,166,247
        BackgroundAlternate=180,190,254
        ForegroundNormal=30,30,46
        ForegroundInactive=30,30,46
        ForegroundActive=30,30,46
        ForegroundLink=30,30,46
        ForegroundVisited=30,30,46
        ForegroundNegative=30,30,46
        ForegroundNeutral=30,30,46
        ForegroundPositive=30,30,46
        DecorationFocus=203,166,247
        DecorationHover=180,190,254

        [Colors:Tooltip]
        BackgroundNormal=24,24,37
        BackgroundAlternate=30,30,46
        ForegroundNormal=205,214,244
        ForegroundInactive=166,173,200
        ForegroundActive=203,166,247
        ForegroundLink=137,180,250
        ForegroundVisited=203,166,247
        ForegroundNegative=243,139,168
        ForegroundNeutral=249,226,175
        ForegroundPositive=166,227,161
        DecorationFocus=203,166,247
        DecorationHover=203,166,247

        [Colors:Complementary]
        BackgroundNormal=17,17,27
        BackgroundAlternate=24,24,37
        ForegroundNormal=205,214,244
        ForegroundInactive=166,173,200
        ForegroundActive=203,166,247
        ForegroundLink=137,180,250
        ForegroundVisited=203,166,247
        ForegroundNegative=243,139,168
        ForegroundNeutral=249,226,175
        ForegroundPositive=166,227,161
        DecorationFocus=203,166,247
        DecorationHover=203,166,247

        [Colors:Header]
        BackgroundNormal=24,24,37
        BackgroundAlternate=30,30,46
        ForegroundNormal=205,214,244
        ForegroundInactive=166,173,200
        ForegroundActive=203,166,247
        ForegroundLink=137,180,250
        ForegroundVisited=203,166,247
        ForegroundNegative=243,139,168
        ForegroundNeutral=249,226,175
        ForegroundPositive=166,227,161
        DecorationFocus=203,166,247
        DecorationHover=203,166,247
      '';
    };

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
