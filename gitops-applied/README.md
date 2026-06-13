The GitOps applied pattern uses Ansible to render Kubernetes manifests and push them to a git repo. 

With this pattern Ansible is only responsible for performing tasks required to render manifests and pushing them to git. Applying the manifests to a cluster is performed by another tool / independent process.

Key points and considerations about this approach:

* Ansible does not need access to a Kubernetes cluster
* Ansible could get live data from a cluster such as reading additional parameters from a ConfigMap
* An independent process is required to perform supplemental tasks such as rebooting a VM when resources are changed.
* This process can enable automatic correction of configuration drift. However, this may add complexity with some configuration items such as the power state of the VM.

There are several methods for applying changes to the cluster such as:
* Executing a pipeline or separate automation task on the git merge event
* Using an CD tool such as ArgoCD

The term "git merge event" is used generically in this document to simply mean that when changes are applied to a specific repo branch. The tools and services used will determine the implementation specifics.

The git merge event triggers the execution of another series of tasks to apply the changes to the cluster. These tasks could handle everything from applying the changes to pre and post application tasks, but they could also trigger independent tasks using events such as the Kubernetes `Event` resource or event system such as Kafka.

Using a CD tool such as ArgoCD has an advantage over git merge events as these tools provide the capability to automatically detect and remediate configuration drift. The use of these tools can place constraints on how pre and post application tasks are triggered and the systems which can be leveraged.

The file `config.env` is ignored by git, you can use this file to set shell variables to simplify using the `Makefile`.
