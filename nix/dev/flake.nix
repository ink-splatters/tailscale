{
  # see https://flake.parts/options/flake-parts-partitions.html
  description = "Dev dependencies inputs flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f8573b9c935cfaa162dd62cc9e75ae2db86f85df";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://pre-commit-hooks.cachix.org"
    ];
    extra-trusted-public-keys = [
      "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
    ];
  };

  outputs = _: {};
}
