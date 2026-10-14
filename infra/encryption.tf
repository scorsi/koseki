# State and plans encrypted (passphrase: sops, via `tofu-state-key`), so terraform.tfstate is committed.
terraform {
  encryption {
    key_provider "external" "sops" {
      command = ["tofu-state-key"]
    }

    key_provider "pbkdf2" "state" {
      chain = key_provider.external.sops
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }

    state {
      method   = method.aes_gcm.state
      enforced = true
    }

    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}
