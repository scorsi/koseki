# CLAUDE.md

See [README.md](README.md) for what the repo is.

- **Comments: English, why not what.** User-facing runtime strings stay in French.
- **One repository = one `repos/<name>.yml`.** Never add per-repository resources by hand in `infra/*.tf`.
- **Verification**: `tofu fmt -recursive`, `tofu validate`, `tofu plan` in `infra/`, from `nix develop`.
  `nix fmt` after touching `flake.nix`. Never `tofu apply`: the owner applies.
- **Destructive**: deleting a `forgejo_repository` deletes the repository with its history. Keep
  `prevent_destroy`, and never change `owner` (it forces a replacement).
- Commits are SSH-signed with a FIDO2 key (a touch); creating commits here is fine.
