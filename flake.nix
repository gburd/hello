{
  description = "A Nix Flake example for ANSI C using GNU Autoconf";

  nixConfig = {
    bash-prompt = "\\[\\e[34;1m\\]flake.nix ~ \\[\\e[0m\\]";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      inherit (nixpkgs) lib;
      officialRelease = false;

      version = lib.fileContents ./.version + versionSuffix;
      versionSuffix =
        if officialRelease
        then ""
        else "pre${builtins.substring 0 8 (self.lastModifiedDate or self.lastModified or "19700101")}_${self.shortRev or "dirty"}";

      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;

            overlays = [
              (final: prev: {
                hello = with final; stdenv.mkDerivation rec {
                  pname = "hello";
                  inherit version;
                  src = ./.;
                  nativeBuildInputs = [ autoreconfHook ];
                };
              })
            ];
          };

        in rec {
          packages = { inherit (pkgs) hello; };
          packages.default = self.packages.${system}.hello;
          packages.container = pkgs.callPackage ./container.nix { package = packages.default; };

          apps.hello = flake-utils.lib.mkApp { drv = packages.default; };
          defaultApp = apps.hello;

          devShells.default = import ./shell.nix { inherit pkgs; };
        }
      );
}
