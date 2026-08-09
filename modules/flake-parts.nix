{ inputs, ... }: {
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [ "x86_64-linux" ];

  # exposes self.debug.options, which is what nixd completes flake-parts options from
  debug = true;
}
