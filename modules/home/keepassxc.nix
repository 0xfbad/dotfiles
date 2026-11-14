_: {
  flake.modules.homeManager.keepassxc =
    { config, lib, ... }:
    let
      # backups stay out of the synced db directory
      backupDir = "${config.xdg.dataHome}/keepassxc/backups";
    in
    {
      # keepassxc has no backup retention
      systemd.user.tmpfiles.rules = [
        "d ${backupDir} 0700 - - 30d"
      ];

      systemd.user.services.keepassxc = {
        Unit = {
          Description = "KeePassXC";
          PartOf = [ config.wayland.systemd.target ];
          After = [ config.wayland.systemd.target ];
        };
        Service = {
          ExecStart = lib.getExe config.programs.keepassxc.package;
          Restart = "on-failure";
        };
        Install.WantedBy = [ config.wayland.systemd.target ];
      };

      programs.keepassxc = {
        enable = true;

        settings = {
          General = {
            BackupBeforeSave = true;
            BackupFilePathPattern = "${backupDir}/{DB_FILENAME}_{TIME:yyyy-MM-dd_HH-mm-ss}.old.kdbx";
            AutoGeneratePasswordForNewEntries = true;
          };

          Browser = {
            Enabled = true;
            SearchInAllDatabases = true;
            BestMatchOnly = true;
            ShowNotification = false;
            AlwaysAllowAccess = true;
            # home-manager writes the manifest
            UpdateBinaryPath = false;
          };

          GUI = {
            MinimizeOnClose = true;
            # classic follows the system qt theme
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
            QuickUnlock = false;
          };

          SSHAgent.Enabled = true;
        };
      };
    };
}
