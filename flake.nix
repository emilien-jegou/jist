{
  description = "Jist - Make or Just but in nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      lib.jist = import ./lib/make-cli.nix;
      lib.cli = pkgs: import ./lib/make-cli.nix { inherit pkgs; };

      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          example = (self.lib.cli pkgs) {
            name = "jist-example";
            desc = "Example CLI built with jist";
            scripts = [
              {
                cmd = "hello";
                desc = "Say hello";
                exec = "echo 'Hello from jist!'";
              }
              {
                cmd = "build";
                desc = "Build the project";
                exec = "echo 'Building...' && sleep 1 && echo 'Done!'";
              }
            ];
          };
        });

      # Allow `nix run .#example`
      defaultPackage = forAllSystems (system: self.packages.${system}.example);
    };
}
