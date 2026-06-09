The GitOps applied pattern uses Ansible to render Kubernetes manifests; applies them to a cluster and then pushes the updated manifests to a git repo.

The goal of this pattern is to keep git as the source of truth while leveraging Ansible to perform additional tasks such as rebooting a VM after hardware configurtion changes.

Key points and considerations about this approach:

* Ansible needs access to the Kubernetes cluster
* Ansible could get live data from a cluster such as reading additional parameters from a ConfigMap
* While git is considered the source of truth, this approach does not automatically correct configuration drift. The Ansible playbook must run to correct configuration drift.

The file `config.env` is ignored by git, you can use this file to set shell variables to simplify using the `Makefile`