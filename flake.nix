{
  description = "Marpit Slides Template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }@inputs:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (self) outputs;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forEachSupportedSystem =
        f:
        lib.genAttrs supportedSystems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            }
          )
        );

      treefmtEval = forEachSupportedSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      checks = forEachSupportedSystem (pkgs: {
        formatting = treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.check self;
      });

      formatter = forEachSupportedSystem (
        pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper
      );

      packages = forEachSupportedSystem (
        pkgs:
        lib.packagesFromDirectoryRecursive {
          directory = ./pkgs;
          # We create a new scope to expose packages to themselves (beware of infinite recursion!)
          callPackage = pkgs.newScope outputs.packages.${pkgs.stdenv.hostPlatform.system};
        }
      );

      devShells = forEachSupportedSystem (pkgs: {
        default = pkgs.callPackage ./shell.nix { };
      });
    };
}
