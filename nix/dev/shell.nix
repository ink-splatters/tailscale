{
  perSystem = {
    config,
    inputs',
    pkgs,
    ...
  }: let
    inherit (config) pre-commit;
    inherit (inputs'.tailscale-go.packages) go_1_26;
  in {
    devShells.default = pkgs.mkShell {
      packages =
        # original Tailscale flake dev shell packages
        # with pkgs; [
        #     curlMinimal
        #     gitMinimal
        #     gopls
        #     gotools
        #     graphviz
        #     perl
        #     yarn
        #
        #     # qemu and e2fsprogs are needed for natlab
        #     qemu
        #     e2fsprogs
        # ] ++
        [
          go_1_26
        ]
        ++ pre-commit.settings.enabledPackages;

      shellHook = ''
        ${pre-commit.installationScript}
      '';
    };
  };
}
