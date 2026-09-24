{
  perSystem =
    { config, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        inherit (config.checks.prek) shellHook;
        buildInputs = [
          pkgs.gnused
          pkgs.just
          pkgs.ripgrep
          pkgs.wget2
        ]
        ++ config.checks.prek.enabledPackages;
      };
    };
}
