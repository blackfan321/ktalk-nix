{
  perSystem =
    { config, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        # Skip git-hooks install in CI (GitHub Actions sets CI=true).
        shellHook = ''
          if [[ -z "''${CI:-}" ]]; then
            ${config.checks.prek.shellHook}
          fi
        '';
        buildInputs = [
          pkgs.gnused
          pkgs.jq
          pkgs.just
          pkgs.nvfetcher
        ]
        ++ config.checks.prek.enabledPackages;
      };
    };
}
