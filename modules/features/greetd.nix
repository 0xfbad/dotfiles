_: {
  flake.modules.nixos.greetd =
    {
      lib,
      pkgs,
      ...
    }:
    {
      services.greetd = {
        enable = true;
        useTextGreeter = true;
        settings = {
          # greetd runs this via sh -c, keep the theme quoted
          default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --remember-session --asterisks --issue --cmd niri-session --theme 'border=magenta;text=white;prompt=magenta;time=blue;action=cyan;button=magenta;container=black;input=white'";
        };
      };
    };
}
