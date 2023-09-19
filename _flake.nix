      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems
        (system:
          with pkgs.${system};

          {
            inherit (self.packages.${system}) hello;

            # Additional tests, if applicable.
            test = stdenv.mkDerivation {
              pname = "hello-test";
              inherit version;

              buildInputs = [ hello ];

              dontUnpack = true;

              buildPhase = ''
                echo 'running some integration tests'
                [[ $(hello) = 'Hello Nixers!' ]]
              '';

              installPhase = "mkdir -p $out";
            };
          }

          // lib.optionalAttrs stdenv.isLinux {
            # A VM test of the NixOS module.
            vmTest =
              with import (nixpkgs + "/nixos/lib/testing-python.nix") {
                inherit system;
              };

              makeTest {
                nodes = {
                  client = { ... }: {
                    imports = [ self.nixosModules.hello ];
                  };
                };

                testScript =
                  ''
                    start_all()
                    client.wait_for_unit("multi-user.target")
                    client.succeed("hello")
                  '';
              };
          }
        );

    };
