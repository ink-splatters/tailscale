{lib, ...}: let
  inherit (lib) makeBinPath optionalString;
in {
  perSystem = {
    config,
    inputs',
    pkgs,
    ...
  }: let
    inherit (config) src;

    buildGo126Module = pkgs.buildGo126Module.override {
      go = inputs'.tailscale-go.packages.go_1_26;
    };

    versionBase = lib.strings.fileContents "${src}/VERSION.txt";
    shortVersion = versionBase;
    longVersion = "${versionBase}-t${config.tailscaleRev}";

    inherit (pkgs) stdenv;
  in {
    # tailscale takes a nixpkgs package set, and builds Tailscale from
    # the same commit as this flake. IOW, it provides "tailscale built
    # from HEAD", where HEAD is "whatever commit you imported the
    # flake at".
    #
    # This is currently unfortunately brittle, because we have to
    # specify vendorHash, and that sha changes any time we alter
    # go.mod. We don't want to force a nix dependency on everyone
    # hacking on Tailscale, so this flake is likely to have broken
    # builds periodically until someone comes through and manually
    # fixes them up. I sure wish there was a way to express "please
    # just trust the local go.mod, vendorHash has no benefit here",
    # but alas.
    #
    # So really, this flake is for tailscale devs to dogfood with, if
    # you're an end user you should be prepared for this flake to not
    # build periodically.
    packages.tailscale = buildGo126Module {
      pname = "tailscale";
      version = shortVersion;
      inherit src;
      vendorHash = lib.fileContents "${src}/go.mod.sri";
      nativeBuildInputs = with pkgs; [
        makeWrapper
        installShellFiles
      ];
      ldflags = [
        "-X tailscale.com/version.shortStamp=${shortVersion}"
        "-X tailscale.com/version.longStamp=${longVersion}"
        "-X tailscale.com/version.gitCommitStamp=${config.tailscaleRev}"
      ];
      env.CGO_ENABLED = 0;
      subPackages = [
        "cmd/tailscale"
        "cmd/tailscaled"
        "cmd/tsidp"
      ];
      doCheck = false;

      # NOTE: We strip the ${PORT} and $FLAGS because they are unset in the
      # environment and cause issues (specifically the unset PORT). At some
      # point, there should be a NixOS module that allows configuration of these
      # things, but for now, we hardcode the default of port 41641 (taken from
      # ./cmd/tailscaled/tailscaled.defaults).
      postInstall =
        optionalString stdenv.isLinux ''
          wrapProgram $out/bin/tailscaled --prefix PATH : ${
            makeBinPath (
              with pkgs; [
                iproute2
                iptables
                getent
                shadow
              ]
            )
          }
          wrapProgram $out/bin/tailscale --suffix PATH : ${makeBinPath [pkgs.procps]}

          sed -i \
            -e "s#/usr/sbin#$out/bin#" \
            -e "/^EnvironmentFile/d" \
            -e 's/''${PORT}/41641/' \
            -e 's/$FLAGS//' \
            ./cmd/tailscaled/tailscaled.service

          install -D -m0444 -t $out/lib/systemd/system ./cmd/tailscaled/tailscaled.service
        ''
        + optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
          installShellCompletion --cmd tailscale \
            --bash <($out/bin/tailscale completion bash) \
            --fish <($out/bin/tailscale completion fish) \
            --zsh <($out/bin/tailscale completion zsh)
        '';
    };
  };
}
