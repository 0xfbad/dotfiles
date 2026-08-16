_: {
  flake.modules.homeManager.claude-wrappers =
    { pkgs, ... }:
    let
      # impure so secretspec set needs no rebuild
      manifest = "/home/fbad/dotfiles/secretspec.toml";

      # secretspec demands --reason inside agents
      getToken = name: secret: ''
        ANTHROPIC_AUTH_TOKEN="$(SECRETSPEC_FILE=${manifest} secretspec get ${secret} --reason "launching ${name}")"
        export ANTHROPIC_AUTH_TOKEN
      '';

      mkClaudeWrapper =
        name: text:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [ pkgs.secretspec ];
          text = text + ''
            exec claude "$@"
          '';
        };
    in
    {
      home.packages = [
        pkgs.secretspec

        # secretspec set MOONSHOT_API_KEY --reason setup first
        # verify the provider with /status, not /model
        (mkClaudeWrapper "claude-kimi" ''
          ${getToken "claude-kimi" "MOONSHOT_API_KEY"}
          # kimi membership uses https://api.kimi.com/coding/ and a console key
          export ANTHROPIC_BASE_URL="https://api.moonshot.ai/anthropic"
          export ANTHROPIC_MODEL="kimi-k3[1m]"
          export ANTHROPIC_DEFAULT_OPUS_MODEL="kimi-k3[1m]"
          export ANTHROPIC_DEFAULT_SONNET_MODEL="kimi-k3[1m]"
          export ANTHROPIC_DEFAULT_HAIKU_MODEL="kimi-k3[1m]"
          export ANTHROPIC_DEFAULT_FABLE_MODEL="kimi-k3[1m]"
          export CLAUDE_CODE_SUBAGENT_MODEL="kimi-k3[1m]"
          export CLAUDE_CODE_AUTO_COMPACT_WINDOW="1000000"
          # moonshot prescribes max
          export CLAUDE_CODE_EFFORT_LEVEL="max"
          export API_TIMEOUT_MS="900000"
          unset ANTHROPIC_API_KEY
        '')

        # secretspec set OPENROUTER_API_KEY --reason setup first
        # model slugs move, recheck with curl -s https://openrouter.ai/api/v1/models | jq -r '.data[].id' | grep openai
        (mkClaudeWrapper "claude-gpt" ''
          ${getToken "claude-gpt" "OPENROUTER_API_KEY"}
          # not /api/v1, claude appends /v1/messages itself
          export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
          export ANTHROPIC_API_KEY=""
          export ANTHROPIC_MODEL="openai/gpt-5.6-sol"
          export ANTHROPIC_DEFAULT_OPUS_MODEL="openai/gpt-5.6-sol"
          export ANTHROPIC_DEFAULT_SONNET_MODEL="openai/gpt-5.6-terra"
          export ANTHROPIC_DEFAULT_HAIKU_MODEL="openai/gpt-5.6-luna"
          export ANTHROPIC_DEFAULT_FABLE_MODEL="openai/gpt-5.6-sol"
          export CLAUDE_CODE_SUBAGENT_MODEL="openai/gpt-5.6-luna"
        '')

        # subscription oauth gateway
        # cli-proxy-api --codex-login or --kimi-login first
        (mkClaudeWrapper "claude-cpa" ''
          export ANTHROPIC_BASE_URL="http://127.0.0.1:8317"
          export ANTHROPIC_AUTH_TOKEN="local-dev-key"
          unset ANTHROPIC_API_KEY
        '')
      ];
    };
}
