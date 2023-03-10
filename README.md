# Terraform-docs GitLab CI

A GitLab CI job for generating Terraform module documentation using terraform-docs and gomplate. In addition to statically defined directory modules, this module can search specific subfolders or parse atlantis.yaml for module identification and doc generation. This action has the ability to auto commit docs to an open PR or after a push to a specific branch.

Refactored for GitLab CI, based on [official terraform-docs github actions](https://github.com/terraform-docs/gh-actions)

# Abstract

The job will run on against an open merge request, generate docs, and add a commit to the MR branch.

More about [merge request pipelines](https://docs.gitlab.com/ee/ci/pipelines/merge_request_pipelines.html)

# Usage

Include job template in your pipeline:

```
include:
  - remote: 'https://github.com/../.gitlab-ci.yml'
```

## Configuration

The job template comes with certain defaults default which can be overwritten by setting the variables in the `.gitlab-ci.yaml` file, the repository variables or pipeline variables. [Cf. CI/CD variable precedence](ttps://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence)

## Example

```
variables:
  INPUT_GIT_PUSH: "true"
  INPUT_GIT_PUSH_USER_NAME: "test"
  INPUT_GIT_PUSH_USER_EMAIL: "foo@bar.com"
  GITLAB_USER: "foobar"

include:
  - remote: 'https://raw.githubusercontent.com/pfeifferj/terraform-docs-gitlab-ci/test/.gitlab-ci.yml'
```
