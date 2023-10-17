Github Workflows
====

## Why we setup github workflows?

- Q: You may have questions, why not use our own system to handle the CI/CD work here (dog food principle).
  > A: We want to use github's build environment to solve the bandwidth problem.
  > Also we want to use the github build environment to publish open source artifacts to ghcr.io and establish an update monitoring mechanism, which is not possible using internal artifactories.
