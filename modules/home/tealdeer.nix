_: {
  flake.homeModules.tealdeer = _: {
    programs.tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };
  };
}
