{ inputs, ... }:
{
  perSystem =
    { config, system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
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
