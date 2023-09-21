{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  #inherit (checks.${system}.pre-commit-check) shellHook;
  DOCKER_BUILDKIT = 1;
  # nativeBuildInputs -- tools you need to run to facilitate the build
  nativeBuildInputs = with pkgs.buildPackages; [ripgrep act];
}
