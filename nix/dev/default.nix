{inputs, ...}: {
  imports = [
    inputs.git-hooks.flakeModule
    ./formatter.nix
    ./pre-commit.nix
    ./shell.nix
  ];
}
