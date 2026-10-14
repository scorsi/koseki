locals {
  github = { for name, r in local.repos : name => {
    description = try(r.github.mirror, false) ? "${r.description} (mirror of my Forgejo)" : r.description
    visibility  = r.github.visibility
    archived    = try(r.github.archived, false)
  } if try(r.github, null) != null }
}

resource "github_repository" "repo" {
  for_each = local.github

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility
  archived    = each.value.archived

  # Everything off for now; pull requests: see below.
  has_issues      = false
  has_wiki        = false
  has_projects    = false
  has_discussions = false

  archive_on_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

# CI runs on Forgejo; GitHub only holds mirrors.
resource "github_actions_repository_permissions" "repo" {
  for_each = github_repository.repo

  repository = each.value.name
  enabled    = false
}

# shortcut: provider 6.13 lacks has_pull_requests (integrations/terraform-provider-github#3479): set
# once through the API, no drift check. Move it into github_repository once a release has it.
resource "terraform_data" "github_no_pull_requests" {
  for_each = github_repository.repo

  triggers_replace = each.value.repo_id

  provisioner "local-exec" {
    command = "gh api --silent -X PATCH repos/${local.owner}/${each.key} -F has_pull_requests=false"
  }
}
