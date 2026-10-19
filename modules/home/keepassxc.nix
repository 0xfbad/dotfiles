_: {
  flake.modules.homeManager.keepassxc =
    { config, lib, ... }:
    let
      # keeps history out of the synced db directory, gives the retention rule a stable path
      backupDir = "${config.xdg.dataHome}/keepassxc/backups";
    in
    {
      # 2.7.12 has no retention of its own, so every save would accumulate forever
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
          Type = "dbus";
          BusName = "org.freedesktop.secrets";
          ExecStart = lib.getExe config.programs.keepassxc.package;
          Restart = "on-failure";
        };
        Install.WantedBy = [ config.wayland.systemd.target ];
      };

      xdg.dataFile."dbus-1/services/org.freedesktop.secrets.service".text = ''
        [D-BUS Service]
        Name=org.freedesktop.secrets
        Exec=/bin/false
        SystemdService=keepassxc.service
      '';

      programs.keepassxc = {
        enable = true;

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
            # no tray, so close locks instead of quitting
            MinimizeOnClose = true;
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
