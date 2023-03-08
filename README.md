# Terraform-docs GitLab CI

A GitLab CI job for generating Terraform module documentation using terraform-docs and gomplate. In addition to statically defined directory modules, this module can search specific subfolders or parse atlantis.yaml for module identification and doc generation. This action has the ability to auto commit docs to an open PR or after a push to a specific branch.

Refactored for GitLab CI, based on [official terraform-docs github actions](https://github.com/terraform-docs/gh-actions)

# Usage

```
include:
  - remote: 'https://github.com/../.gitlab-ci.yml'
```

## Configuration

Overwrite defaults:

Repo vars, pipeline vars
