_: {
  flake.modules.homeManager.keepassxc =
    { config, ... }:
    let
      # keeps history out of the synced db directory, gives the retention rule a stable path
      backupDir = "${config.xdg.dataHome}/keepassxc/backups";
    in
    {
      # the keepassxc module asserts on this whenever autostart is set
      xdg.autostart.enable = true;

      # 2.7.12 has no retention of its own, so every save would accumulate forever
      systemd.user.tmpfiles.rules = [
        "d ${backupDir} 0700 - - 30d"
      ];

      programs.keepassxc = {
        enable = true;
        # gnome-keyring is gone, so this is the only org.freedesktop.secrets owner
        autostart = true;

        settings = {
          General = {
            BackupBeforeSave = true;
            # {TIME} keeps every save instead of one rolling copy, aged out by the rule above
            BackupFilePathPattern = "${backupDir}/{DB_FILENAME}_{TIME:yyyy-MM-dd_HH-mm-ss}.old.kdbx";
            AutoGeneratePasswordForNewEntries = true;
          };

          Browser = {
            Enabled = true;
            SearchInAllDatabases = true;
            BestMatchOnly = true;
            ShowNotification = false;
            # home-manager handles the native messaging manifest
            UpdateBinaryPath = false;
          };

          GUI = {
            # still serves fdosecrets, ssh agent, and browser integration
            MinimizeOnStartup = true;
            # defer to the darkly/catppuccin system theme
            ApplicationTheme = "classic";
            CompactMode = true;
            ColorPasswords = true;
            MonospaceNotes = true;
          };

          Security = {
            ClearSearch = true;
            LockDatabaseIdleSeconds = 300;
            LockDatabaseMinimize = true;
            EnableCopyOnDoubleClick = true;
          };

          SSHAgent.Enabled = true;

          FdoSecrets.Enabled = true;
        };
      };
    };
}
