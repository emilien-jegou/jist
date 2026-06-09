# jist

## Quick Start

### Flake Usage (Recommended)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jist.url = "github:yourusername/jist";
  };

  outputs = { nixpkgs, jist, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = jist.lib.cli pkgs {
        name = "mytool";
        desc = "My awesome development CLI";

        scripts = [
          {
            cmd = "prepare";
            desc = "Build the project";
            visible = false;
            exec = "cargo build --release";
          }
          {
            cmd = "test";
            desc = "Run tests";
            exec = "cargo test";
            deps = [ "prepare" ];
          }
          {
            cmd = "dev";
            desc = "Start development server";
            exec = "cargo run";
            dir = "./backend";
          }
        ];
      };
    };
}
