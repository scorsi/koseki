# koseki (戸籍)

Registry of my repositories, in OpenTofu: which ones exist on Forgejo and on GitHub, their settings,
and the push mirrors from Forgejo to GitHub. One file per repository in `repos/<name>.yml`; the
format is documented at the top of `infra/main.tf`, the OpenTofu code that applies it.

[sekkeizu](https://github.com/scorsi/sekkeizu) runs Forgejo; what lives inside it is declared here.

## Usage

```bash
nix develop        # or direnv: tofu, sops, the FIDO2 plugin, tofu-state-key, GITHUB_TOKEN from gh
cd infra
tofu init
tofu plan
tofu apply
```

Each run decrypts `secrets/tofu.yaml` (state passphrase, tokens): a touch on a FIDO2 key per decryption.

- **Add a repository**: a new `repos/<name>.yml`, `tofu apply`, then push to Forgejo; the mirror follows.
- **Remove one**: refused (`prevent_destroy`). Delete it by hand, then `tofu state rm`.

## Encrypted tree

`secrets/` is encrypted by git-crypt (`.gitattributes`) with **sekkeizu's key**, on top of sops:
ciphertext in the repository, plain in an unlocked clone. A locked clone can't run tofu (the state
passphrase is in there).

- **Unlock a clone**: `git-crypt unlock <key>` (the key is sekkeizu's, see its README, "Encrypted
  trees"; from an unlocked sekkeizu: `git-crypt unlock ../sekkeizu/.git/git-crypt/keys/default`),
  then `git config core.hooksPath scripts/hooks`.
- `scripts/hooks/pre-commit` refuses a commit that would store `secrets/` in clear (a clone that was
  never unlocked skips the filter without a word).

## Secrets (`secrets/tofu.yaml`, sops)

- `state_passphrase`: encrypts the state and plans, so `terraform.tfstate` is committed.
- `forgejo_api_token`: Forgejo token of the owner, scopes `write:repository` and `write:user`.
- `github_mirror_token`: fine-grained GitHub token, *All repositories* (a new mirror needs no
  change to it), *Contents: read and write*. Handed to Forgejo by the push mirrors. It expires: the reminder lives in sekkeizu
  (`sekkeizu.expiringSecrets.github-mirror-token`, notified on jiban).

GitHub itself takes `gh auth token` (scope `repo`: it can create and edit, not delete).
