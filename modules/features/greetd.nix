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

          # luks unlock gates auth at boot so the first session skips the greeter
          initial_session = {
            # logout falls back to default_session, setting this drops systemd Restart=
            command = "niri-session";
            user = "fbad";
          };
        };
      };
    };
}
