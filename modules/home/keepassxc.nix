_: {
  flake.homeModules.keepassxc = _: {
    programs.keepassxc = {
      enable = true;

      settings = {
        General = {
          SingleInstance = true;
          RememberLastDatabases = true;
          OpenPreviousDatabasesOnStartup = true;
          AutoSaveAfterEveryChange = true;
          AutoSaveOnExit = true;
          UseAtomicSaves = true;
          BackupBeforeSave = true;
          BackupFilePathPattern = "{DB_FILENAME}.old.kdbx";
          MinimizeOnCopy = true;
          DropToBackgroundOnCopy = true;
          UseGroupIconOnEntryCreation = true;
        };

        Browser = {
          Enabled = true;
          SearchInAllDatabases = true;
          UnlockDatabase = true;
          MatchUrlScheme = true;
          SupportBrowserProxy = true;
          # home-manager handles the native messaging manifest
          UpdateBinaryPath = false;
        };

        GUI = {
          # defer to kvantum/catppuccin system theme
          ApplicationTheme = "classic";
          CompactMode = true;
          HidePasswords = true;
          ColorPasswords = true;
          MonospaceNotes = true;
          ShowTrayIcon = true;
          MinimizeToTray = true;
          MinimizeOnClose = true;
          MinimizeOnStartup = false;
          CheckForUpdates = false;
          ShowExpiredEntriesOnDatabaseUnlock = true;
          ShowExpiredEntriesOnDatabaseUnlockOffsetDays = 3;
        };

        Security = {
          ClearClipboard = true;
          ClearClipboardTimeout = 10;
          ClearSearch = true;
          ClearSearchTimeout = 5;
          LockDatabaseIdle = true;
          LockDatabaseIdleSeconds = 300;
          LockDatabaseScreenLock = true;
          LockDatabaseOnUserSwitch = true;
          HidePasswordPreviewPanel = true;
          EnableCopyOnDoubleClick = true;
        };

        SSHAgent.Enabled = true;

        FdoSecrets = {
          Enabled = true;
          ShowNotification = true;
          ConfirmAccessItem = true;
          ConfirmDeleteItem = true;
          UnlockBeforeSearch = true;
        };

        PasswordGenerator = {
          Length = 24;
          LowerCase = true;
          UpperCase = true;
          Numbers = true;
          SpecialChars = true;
          ExcludeAlike = true;
          EnsureEvery = true;
        };
      };
    };
  };
}
