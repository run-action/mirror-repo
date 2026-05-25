{
  description = "Development environment for git-mirror action";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              bats
              git
              gnumake
              shellcheck
              yq-go
            ];

            shellHook = ''
              echo "Run tests with: make test"
            '';
          };
        });

      checks = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          bats = pkgs.runCommand "git-mirror-bats" {
            nativeBuildInputs = with pkgs; [
              bats
              git
              gnumake
              shellcheck
              yq-go
            ];
          } ''
            cp -R ${./.} source
            cd source
            make test
            touch $out
          '';
        });
    };
}
