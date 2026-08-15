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
          # greetd runs this through sh -c, so the semicolons in the theme spec need quoting
          default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --remember-session --asterisks --issue --cmd niri-session --theme 'border=magenta;text=white;prompt=magenta;time=blue;action=cyan;button=magenta;container=black;input=white'";
        };
      };
    };
}
