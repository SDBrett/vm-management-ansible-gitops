
# Overview

This is a personal learning repo that examines incorporating imperative processes with a GitOps based process for managing VMs on OpenShift.

The repo contains two distinct patterns:
1. (GitOps Applied)[gitops-applied/README.md] - Where the rendered manifests are applied using a CD tool such as ArgoCD
2. (Ansible Applied)[ansible-applied/README.md] - Where Ansible applies rendered manifests.

Both patterns use GitOps as the single source of truth and render manifests based on variables contained in a file.

# How to Use

## Services

The `hack` directory contains two python scripts which simulate iteractions with external systems. These scripts are added to enable testing different scenarioes such as:

* Add data from external system to a manifest
* Clean up on failure and removal
* Detect if data is missing from manifests already stored in Git.

The CMDB service is used to simulate adding the VM to a CMDB service and removing the entry when the VM is removed.

The IPAM service simulates an IP system and will return a random IP address that is added to the rendered manifests.

The services are required for the playbooks to work, root `Makefile` has targets to start and stop these services.

To start the services run `make start-services`
To stop the services run `make stop-services`

Default service ports are 8080 and 8081

## Git Service
The playbooks require access to a git service, the root `Makefile` has a target to run a gitea container image for those who want to use a local git service.

## First run

Use `make setup-gitea` when first running Gitea, this will start the container and create the user `admin` with the password `ansible123`.

You will then need to setup a git repo

After the first run of gitea you can use `make start-gitea` to start the container.

To stop the service run: `make stop-gitea`

The playbooks use the following variables for git:

```
repo_url
repo_dir
repo_branch
```

NOTE: That before running any playbook the remote git repo will need to be created

# Use of AI in the project
AI has been used to help with the following parts of this project:
* Python scripts
* Makefile

Ansible content and documentation is all handcut goodness
