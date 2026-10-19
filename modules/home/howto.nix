_: {
  flake.modules.homeManager.howto =
    { config, pkgs, ... }:
    let
      manifest = "${config.home.homeDirectory}/dotfiles/secretspec.toml";

      howto-query = pkgs.writeShellApplication {
        name = "howto-query";
        runtimeInputs = [
          pkgs.curl
          pkgs.jq
          pkgs.secretspec
        ];
        text = ''
          key="$(SECRETSPEC_FILE=${manifest} secretspec get -P default OPENROUTER_API_KEY --reason "howto")"
          model="''${HOWTO_MODEL:-openai/gpt-6-luna}"

          body="$(
            jq -n --arg q "$*" --arg model "$model" '{
              model: $model,
              max_tokens: 500,
              reasoning: {effort: "none"},
              messages: [
                {role: "system", content: "Turn the request into one zsh command for NixOS Linux. Reply with only the command: no explanation, no markdown, no code fences."},
                {role: "user", content: $q}
              ]
            }'
          )"

          resp="$(
            curl -H @<(printf 'Authorization: Bearer %s\n' "$key") \
              -sS --fail-with-body --max-time 30 \
              -H 'Content-Type: application/json' \
              -d @- \
              https://openrouter.ai/api/v1/chat/completions <<<"$body"
          )" || {
            jq -r '.error.message // .' <<<"$resp" >&2
            exit 1
          }

          jq -r '
            .choices[0]
            | if .message.content then
                .message.content
                | sub("^\\s*```[a-z]*\\n"; "")
                | sub("\\n?```\\s*$"; "")
              else
                "no command, finish_reason \(.finish_reason)\n" | halt_error(1)
              end
          ' <<<"$resp"
        '';
      };
    in
    {
      home.packages = [ howto-query ];

      programs.zsh = {
        shellAliases.howto = "noglob howto";

        siteFunctions.howto = ''
          (( $# < 1 )) && { print -u2 "usage: howto <what you want to do>"; return 1 }
          local cmd
          cmd=$(howto-query "$*") || return 1
          # a child process needs TIOCSTI to fill the buffer and the kernel blocks it
          print -z -- "$cmd"
        '';
      };
    };
}
