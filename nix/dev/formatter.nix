{
  perSystem = {
    pkgs,
    inputs',
    ...
  }: {
    formatter = pkgs.writeShellScriptBin "fmt-all" ''
      ${pkgs.alejandra}/bin/alejandra .

      # echo "Formatting Go files..."
      # ${inputs'.tailscale-go.packages.go_1_26}/bin/go fmt ./...
    '';
  };
}
