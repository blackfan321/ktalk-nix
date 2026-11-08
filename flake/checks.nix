{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      prek = inputs.git-hooks.lib.${system}.run {
        src = inputs.self;
        package = pkgs.prek;
        hooks = {
          nixfmt = {
            enable = true;
            priority = 1;
          };

          deadnix = {
            enable = true;
            priority = 2;
            # nvfetcher always emits unused fetcher args in generated.nix
            excludes = [ "_sources/generated.nix" ];
          };

          statix = {
            enable = true;
            priority = 3;
          };
        };
      };
    in
    {
      checks.prek = prek;
    };
}
