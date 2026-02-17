# flake.nix describes a Nix source repository that provides
# development builds of Tailscale and the fork of the Go compiler
# toolchain that Tailscale maintains. It also provides a development
# environment for working on tailscale, for use with "nix develop".
#
# For more information about this and why this file is useful, see:
# https://wiki.nixos.org/wiki/Flakes
#
# Also look into direnv: https://direnv.net/, this can make it so that you can
# automatically get your environment set up when you change folders into the
# project.
{
  inputs = {
    # Used by shell.nix as a compat shim.
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    tailscale-go = {
      url = "github:ink-splatters/tailscale-go/go1.26+20260217";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        flake-parts.follows = "flake-parts";
      };
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  nixConfig = {
    extra-substituters = [
      "https://aarch64-darwin.cachix.org"
    ];
    extra-trusted-public-keys = [
      "aarch64-darwin.cachix.org-1:mEz8A1jcJveehs/ZbZUEjXZ65Aukk9bg2kmb0zL9XDA="
    ];
  };

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} (let
      systems = import inputs.systems;
      flakeModules.default = import ./nix/flake-module.nix;
    in {
      imports = [
        flakeModules.default
        flake-parts.flakeModules.partitions
      ];

      inherit systems;

      partitionedAttrs = {
        apps = "dev";
        checks = "dev";
        devShells = "dev";
        formatter = "dev";
      };
      partitions.dev = {
        extraInputsFlake = ./nix/dev;
        module = {
          imports = [./nix/dev];
        };
      };

      perSystem = {
        config,
        lib,
        ...
      }: {
        options = {
          # used to avoid relative paths with parent references
          src = lib.mkOption {
            default = builtins.path {
              path = ./.;
              name = "tailscale";
            };
          };
          tailscaleRev = lib.mkOption {
            type = lib.types.str;
            default = builtins.toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
          };
        };
        config.packages.default = config.packages.tailscale;
      };

      # exports
      flake = {
        inherit flakeModules;
      };
    });
}
