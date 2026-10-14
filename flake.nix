{
  description = "koseki — registry of my repositories: Forgejo, GitHub and the push mirrors between them, in OpenTofu";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # External key provider of OpenTofu's state encryption (encryption.tf): hands the state
          # passphrase from sops straight to tofu, so it never sits in the environment or on disk.
          # Protocol: a header line, then the keys as JSON; "null" on stdin means nothing to decrypt.
          # Same as sekkeizu's (modules/flake/infra.nix), reading this repo's secrets file.
          tofuStateKey = pkgs.writeShellApplication {
            name = "tofu-state-key";
            runtimeInputs = with pkgs; [
              coreutils
              git
              sops
              age-plugin-fido2-hmac
            ];
            text = ''
              echo '{"magic":"OpenTofu-External-Key-Provider","version":1}'
              input=$(cat)
              repo=$(git rev-parse --show-toplevel)
              key=$(sops -d --extract '["state_passphrase"]' "$repo/secrets/tofu.yaml" | base64 -w0)
              [ -n "$key" ] || { echo "passphrase de l'état introuvable dans secrets/tofu.yaml" >&2; exit 1; }
              if [ "$input" = null ]; then
                printf '{"keys":{"encryption_key":"%s"},"meta":{"external_data":{}}}' "$key"
              else
                printf '{"keys":{"encryption_key":"%s","decryption_key":"%s"},"meta":{"external_data":{}}}' "$key" "$key"
              fi
            '';
          };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              opentofu
              sops
              age
              age-plugin-fido2-hmac # secrets/ is encrypted to the FIDO2 keys: a touch per decryption
              tofuStateKey
            ];
            # The GitHub provider takes gh's OAuth token (scope `repo`: create and edit, never delete)
            # rather than a PAT kept in sops: one secret fewer, and nothing that expires.
            shellHook = ''
              export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
              command -v gh >/dev/null && GITHUB_TOKEN=$(gh auth token 2>/dev/null) && export GITHUB_TOKEN
            '';
          };
        }
      );
    };
}
