locals {
  forgejo = { for name, r in local.repos : name => {
    description = r.description
    private     = r.forgejo.private
  } if try(r.forgejo, null) != null }

  forgejo_mirrors = toset([for name, r in local.repos : name if contains(keys(local.forgejo), name) && try(r.github.mirror, false)])
}

resource "forgejo_repository" "repo" {
  for_each = local.forgejo

  # No owner: set, it means an organization (and changing it replaces, i.e. deletes, the repository).
  name        = each.key
  description = each.value.description
  private     = each.value.private # explicit: the provider defaults to true

  # Everything off for now, except Actions (the CI).
  has_actions       = true
  has_issues        = false
  has_pull_requests = false
  has_wiki          = false
  has_projects      = false
  has_releases      = false
  has_packages      = false

  # Destroy deletes the repository: no archive option.
  lifecycle {
    prevent_destroy = true
  }
}

# Every argument forces a replacement: a new token recreates the mirrors.
resource "forgejo_repository_push_mirror" "github" {
  for_each = local.forgejo_mirrors

  owner           = local.owner
  repository      = forgejo_repository.repo[each.key].name
  remote_address  = "${github_repository.repo[each.key].html_url}.git"
  remote_username = local.owner
  remote_password = data.sops_file.secrets.data["github_mirror_token"]
}
