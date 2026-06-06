The GitOps applied pattern uses Ansible to render Kubernetes manifests and push them to a git repo. 

With this pattern Ansible is only responsible to performing tasks required to render manifests and pushing them to git. Applying the manifests to a cluster is performed by a CD tool such as ArgoCD.

Key points and considerations about this approach:

* Ansible does not need access to a Kubernetes cluster
* Ansible could get live data from a cluster such as reading additional parameters from a ConfigMap
* An independent process is required to perform supplemental tasks such as rebooting a VM when resources are changed.

The file `config.env` is ignored by git, you can use this file to set shell variables to simplify using the `Makefile`