This is a learning process that examines incorporating imparative tasks with GitOps for managing virtual machines on OpenShift.

The hack directory contains two Python scripts which simulate iteractions with external systems.

The cmdb simulation returns a UUID and the IPAM simulation will return a random IP address.

The services need to be running for the playbook to work else it will fail when trying to interact with them.

To start the services run `make start-services`
To stop the services run `make stop-services`

Default service ports are 8080 and 8081

The playbook can be run using either `ansible-playbook playbook.yaml` or `make run-playbook`

The file `config.env` is ignored by git, you can use this file to set shell variables to simplify using the `Makefile`