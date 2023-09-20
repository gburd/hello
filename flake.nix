{
  description = "A Nix Flake example for ANSI C using GNU Autoconf";

  nixConfig = {
    bash-prompt = "\\[\\e[34;1m\\]hello.nix ~ \\[\\e[0m\\]";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    zicross.url = "github:flyx/Zicross";
  };
  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  inputs.nix-github-actions.url = "github:nix-community/nix-github-actions";
  inputs.nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks, nix-github-actions, zicross }:
    let
      inherit (nixpkgs) lib;
      officialRelease = false;

      version = lib.fileContents ./.version + versionSuffix;
      versionSuffix =
        if officialRelease
        then ""
        else "pre${builtins.substring 0 8 (self.lastModifiedDate or self.lastModified or "19700101")}_${self.shortRev or "dirty"}";

      #supportedSystems = [ "i386-linux" "x86_64-linux" "armv6l-linux" "armv7l-linux" "aarch64-linux" "powerpc64le-linux" "riscv64-linux" "x86_64-darwin" "aarch64-darwin" "x86_64-windows" "x86_64-windows" ];
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # Generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });

    in
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;

            overlays = [
              #zicross.overlays.zig
              #zicross.overlays.debian
              #zicross.overlays.windows

              (final: prev: {
                #hello = with final; (if lib.strings.hasSuffix "windows" system then zigStdenv else stdenv).mkDerivation rec {
                hello = with final; stdenv.mkDerivation rec {
                  inherit version system;
                  pname = "hello";
                  src = self;
                  configureFlags = [
                    "--host ${system}"
                  ];
                  nativeBuildInputs = [ autoreconfHook ];
                  meta = {
                    maintainers = [ "Greg Burd <greg@burd.me>" ];
                    downloadPage = "https://github.com/gburd/hello/releases";
                    changelog = "https://raw.githubusercontent.com/gburd/hello/main/ChangeLog";
                    platforms = supportedSystems;
                    homepage = "https://github.com/gburd/hello";
                    license = "https://github.com/gburd/hello/LICENSE";
                    mainProgram = "hello";
                  };
                };
              })
            ];

            checks = {
              pre-commit-check = pre-commit-hooks.lib.${system}.run {
                src = ./.;
                hooks = {
                  nixpkgs-fmt.enable = true;
                };
              };
            };

            devShell = nixpkgs.legacyPackages.${system}.mkShell {
              inherit (self.checks.${system}.pre-commit-check) shellHook;
            };

          };

        in rec {
          packages = {
            inherit (pkgs) hello;

            # This changes things in "packages" below of the form: "packages.x86_64-linux" into
            # "githubActions.targets.x86_64-linux.hello" so that the GHA matrix can iterate over them.
            githubActions = nix-github-actions.lib.mkGithubMatrix {
              checks = nixpkgs.lib.getAttrs supportedSystems self.packages;
            };
          };
          packages.default = self.packages.${system}.hello;

          #packages.lxc = pkgs.callPackage ./nix/lxc.nix { package = packages.default; };
          #packages.x86_64-windows = pkgs.callPackage ./nix/pkg-win64zip.nix { package = packages.default; };
          #packages.x86_64-wix = pkgs.callPackage ./nix/pkg-win64-wix.nix { inherit pkgs packages; };

          #apps.hello = flake-utils.lib.mkApp { drv = packages.default; };
          #apps.${system}.default = apps.hello;

          #devShells.default = import ./shell.nix { inherit pkgs; };
        }
      );
}
