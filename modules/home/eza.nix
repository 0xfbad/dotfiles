_: {
  flake.modules.homeManager.eza = _: {
    programs.eza = {
      enable = true;
      git = true;
      extraOptions = [ "--group-directories-first" ];
    };

    # the icons option is only a zsh alias, fzf previews miss it
    home.sessionVariables.EZA_ICONS_AUTO = "1";
  };
}
