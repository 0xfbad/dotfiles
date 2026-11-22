# env config reaches every git call, including ones the bash guard cannot parse
hook: {
  GIT_CONFIG_COUNT = "5";
  GIT_CONFIG_KEY_0 = "hook.agent-push.event";
  GIT_CONFIG_VALUE_0 = "pre-push";
  GIT_CONFIG_KEY_1 = "hook.agent-push.command";
  GIT_CONFIG_VALUE_1 = "${hook} pre-push";
  GIT_CONFIG_KEY_2 = "hook.agent-msg.event";
  GIT_CONFIG_VALUE_2 = "commit-msg";
  GIT_CONFIG_KEY_3 = "hook.agent-msg.command";
  GIT_CONFIG_VALUE_3 = "${hook} commit-msg";
  GIT_CONFIG_KEY_4 = "pull.rebase";
  GIT_CONFIG_VALUE_4 = "true";
}
