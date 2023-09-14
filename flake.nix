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

  outputs = { self, nixpkgs, flake-utils, zicross }:
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
              zicross.overlays.zig
              zicross.overlays.debian
              zicross.overlays.windows

              (final: prev: {
                hello = with final; zigStdenv.mkDerivation rec {
                  inherit version;
                  inherit system;
                  pname = "hello";
                  src = self;
                  configureFlags = [
                    "--host ${system}"
                  ];
                  nativeBuildInputs = [ autoreconfHook ];
                  meta = {
                    maintainers = [ "Symas Corporation <support@symas.com>" "Greg Burd <gburd@symas.com>" ];
                    homepage = "https://github.com/openldap/openldap";
                    license = licenses.openldap;
                    mainProgram = "hello";
                  };
                };
              })
            ];
          };

        in rec {
          packages = { inherit (pkgs) hello; };
          packages.default = self.packages.${system}.hello;
          packages.container = pkgs.callPackage ./container.nix { package = packages.default; };
          #packages.win64zip = pkgs.callPackage ./win64zip.nix { package = packages.default; };
          packages.win64zip = pkgs.packageForWindows packages.default {
            targetSystem = "x86_64-windows";
            appendExe = [ "hello" ];
            deps = {
              libcpp = {
                tail = "libc++-14.0.3-1-any.pkg.tar.zst";
                sha256 = "1r73zs9naislzzjn7mr3m8s6pikgg3y4mv550hg09gcsjc719kzz";
              };
            };
          };

          apps.hello = flake-utils.lib.mkApp { drv = packages.default; };
          apps.${system}.default = apps.hello;

          devShells.default = import ./shell.nix { inherit pkgs; };
        }
      );
}
