{
  description = "An over-engineered Hello World in C";

  # Nixpkgs / NixOS version to use.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number for our target.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
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
          packages.container = pkgs.dockerTools.buildImage {
            name = "hello";
            tag = "0.1.0";
            created = "now";
            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = [ packages.default ];
              pathsToLink = [ "/bin" ];
            };
            config.Cmd = [ "${packages.default}/bin/hello" ];
          };

          apps.hello = flake-utils.lib.mkApp { drv = packages.hello; };
          defaultApp = apps.hello;
          # devShells.default = import ./shell.nix { inherit pkgs; };
        }
      );
}
