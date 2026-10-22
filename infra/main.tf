terraform {
  required_providers {
    forgejo = {
      source  = "adyxax/forgejo"
      version = "1.6.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}

locals {
  owner       = "scorsi"
  forgejo_url = "https://forgejo.uchi.scorsi.dev"
}

# Not ephemeral: the mirror token is a plain argument, it lands in the (encrypted) state anyway.
data "sops_file" "secrets" {
  source_file = "${path.module}/../secrets/tofu.yaml"
}

provider "forgejo" {
  base_uri  = local.forgejo_url
  api_token = data.sops_file.secrets.data["forgejo_api_token"]
}

# Token: GITHUB_TOKEN, from `gh auth token` (devShell).
provider "github" {
  owner = local.owner
}

# One file per repository, repos/<name>.yml:
#   description: required, shared by both sides.
#   forgejo:     { private }, absent if not on Forgejo.
#   github:      { visibility, archived?, mirror? }, absent if not on GitHub. `mirror`: Forgejo
#                pushes to it, and the description says so.
locals {
  repos = { for f in fileset("${path.module}/../repos", "*.yml") :
    trimsuffix(f, ".yml") => yamldecode(file("${path.module}/../repos/${f}"))
  }
}

