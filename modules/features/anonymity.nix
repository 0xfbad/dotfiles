_: {
  flake.modules.nixos.anonymity = _: {
    services.tor = {
      enable = true;
      client.enable = true;
      torsocks.enable = true;
    };

    services.dnscrypt-proxy = {
      enable = true;
      settings = {
        listen_addresses = [
          "127.0.0.1:53"
          "[::1]:53"
          # docker strips loopback nameservers
          "172.17.0.1:53"
        ];

        # upstream default bootstraps plaintext to quad9 and google and holds nss-lookup.target 60s offline
        bootstrap_resolvers = [ "9.9.9.9:53" ];
        netprobe_address = "9.9.9.9:53";
        netprobe_timeout = 10;

        dnscrypt_servers = false;
        require_dnssec = true;

        # quic only where alt-svc advertises it, http3_probe stays off since it slows servers without h3
        http3 = true;

        # setting sources replaces the whole upstream table, both subtables restated
        sources = {
          public-resolvers = {
            urls = [
              "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
              "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
              "https://cdn.jsdelivr.net/gh/DNSCrypt/dnscrypt-resolvers@master/v3/public-resolvers.md"
            ];
            # absolute or it resolves into /nix/store and refetches every start
            cache_file = "/var/cache/dnscrypt-proxy/public-resolvers.md";
            minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
            refresh_delay = 73;
            prefix = "";
          };

          relays = {
            urls = [
              "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md"
              "https://download.dnscrypt.info/resolvers-list/v3/relays.md"
              "https://cdn.jsdelivr.net/gh/DNSCrypt/dnscrypt-resolvers@master/v3/relays.md"
            ];
            cache_file = "/var/cache/dnscrypt-proxy/relays.md";
            minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
            refresh_delay = 73;
            prefix = "";
          };
        };
      };
    };

    services.resolved = {
      enable = true;
      settings.Resolve = {
        # unreachable while DNS= is set, keeps the builtin cloudflare and google fallbacks out
        FallbackDNS = [
          "127.0.0.1"
          "::1"
        ];
        LLMNR = false;
        MulticastDNS = false;
      };
    };
  };
}
