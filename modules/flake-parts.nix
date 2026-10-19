{ inputs, ... }: {
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [ "x86_64-linux" ];

  # nixd completes flake-parts options from self.debug.options
  debug = true;
}
