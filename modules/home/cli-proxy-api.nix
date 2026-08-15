{ inputs, ... }: {
  flake.modules.homeManager.cli-proxy-api =
    { pkgs, ... }:
    let
      cli-proxy-api = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.cli-proxy-api;
    in
    {
      # cli for the oauth logins
      home.packages = [ cli-proxy-api ];

      home.file.".cli-proxy-api/config.yaml".text = ''
        host: "127.0.0.1"
        port: 8317
        auth-dir: "~/.cli-proxy-api"
        api-keys:
          - "local-dev-key"
      '';

      systemd.user.services.cli-proxy-api = {
        Unit.Description = "CLIProxyAPI gateway";
        Service = {
          ExecStart = "${cli-proxy-api}/bin/cli-proxy-api --config %h/.cli-proxy-api/config.yaml";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
