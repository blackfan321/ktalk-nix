{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages = rec {
        ktalk = pkgs.callPackage ../ktalk.nix { };
        default = ktalk;
      };
    };
}
