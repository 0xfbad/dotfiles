_: {
  flake.homeModules.zoxide = {lib, ...}: {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = false;
      options = [
        "--cmd"
        "cd"
      ];
    };
    # zoxide must init after all other shell integrations to avoid its doctor warning
    programs.zsh.initContent = lib.mkOrder 5000 ''
      eval "$(zoxide init zsh --cmd cd)"
    '';
  };
}
