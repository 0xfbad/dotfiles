_: {
  flake.homeModules.zoxide = _: {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--cmd"
        "cd"
      ];
    };
    # doctor warning nags about init order, we don't care
    home.sessionVariables._ZO_DOCTOR = "0";
  };
}
