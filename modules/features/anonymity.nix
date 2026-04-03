_: {
  flake.nixosModules.anonymity = _: {
    services.tor = {
      enable = true;
      client.enable = true;
    };

    services.dnscrypt-proxy = {
      enable = true;
      settings = {
        listen_addresses = ["127.0.0.1:53" "[::1]:53"];

        max_clients = 250;

        dnscrypt_servers = false;
        doh_servers = true;
        odoh_servers = false;
        ipv4_servers = true;
        ipv6_servers = false;

        require_dnssec = true;
        require_nolog = true;
        require_nofilter = true;

        sources.public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "public-resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
      };
    };

    services.resolved = {
      enable = true;
      settings.Resolve = {
        FallbackDNS = "127.0.0.1 ::1";
        LLMNR = false;
        MulticastDNS = false;
      };
    };
  };
}
