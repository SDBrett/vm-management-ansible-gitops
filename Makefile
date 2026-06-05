PYTHON ?= python3
ANSIBLE ?= ansible-playbook
HACK_DIR := hack
RUN_DIR := .run
PLAYBOOK ?= playbook.yaml
INVENTORY ?= inventory.yaml
ANSIBLE_ARGS ?=

CMDB_HOST ?= localhost
CMDB_PORT ?= 8080
IPAM_HOST ?= localhost
IPAM_PORT ?= 8081
CMDB_URL ?= http://localhost:$(CMDB_PORT)
IPAM_URL ?= http://localhost:$(IPAM_PORT)

GITEA_CONTAINER ?= gitea
GITEA_HTTP_PORT ?= 3000
GITEA_SSH_PORT ?= 22220
GITEA_VOLUME ?= gitea-data
GITEA_IMAGE ?= gitea/gitea:latest
GITEA_URL ?= http://localhost:$(GITEA_HTTP_PORT)
CONTAINER_TOOL ?= podman

CMDB_PIDFILE := $(RUN_DIR)/cmdb.pid
IPAM_PIDFILE := $(RUN_DIR)/ipam.pid
CMDB_LOG := $(RUN_DIR)/cmdb.log
IPAM_LOG := $(RUN_DIR)/ipam.log

.PHONY: help start-cmdb stop-cmdb start-ipam stop-ipam start-gitea stop-gitea start-services stop-services status run-playbook

.DEFAULT_GOAL := help

help:
	@echo "Mock API servers for Ansible VM GitOps testing"
	@echo ""
	@echo "Targets:"
	@echo "  make start-cmdb       Start CMDB in the background ($(CMDB_HOST):$(CMDB_PORT))"
	@echo "  make stop-cmdb        Stop CMDB using $(CMDB_PIDFILE)"
	@echo "  make start-ipam       Start IPAM in the background ($(IPAM_HOST):$(IPAM_PORT))"
	@echo "  make stop-ipam        Stop IPAM using $(IPAM_PIDFILE)"
	@echo "  make start-gitea      Start Gitea in a container ($(GITEA_URL))"
	@echo "  make stop-gitea       Stop the Gitea container"
	@echo "  make start-services   Start both CMDB and IPAM"
	@echo "  make stop-services    Stop both CMDB and IPAM"
	@echo "  make status           Show whether each service is running"
	@echo "  make run-playbook     Run $(PLAYBOOK) with cmdb_url and ipam_url"
	@echo ""
	@echo "Variables:"
	@echo "  CMDB_HOST, CMDB_PORT   CMDB bind address (default port: 8080)"
	@echo "  IPAM_HOST, IPAM_PORT   IPAM bind address (default port: 8081)"
	@echo "  CMDB_URL, IPAM_URL     URLs passed to the playbook as extra vars"
	@echo "  CONTAINER_TOOL          Container tool for Gitea targets (default: podman)"
	@echo "  GITEA_CONTAINER        Container name (default: gitea)"
	@echo "  GITEA_HTTP_PORT        Gitea web UI port (default: 3000)"
	@echo "  GITEA_SSH_PORT         Gitea SSH port mapped to container port 22 (default: 22220)"
	@echo "  GITEA_VOLUME           Container volume for Gitea data (default: gitea-data)"
	@echo "  GITEA_IMAGE            Gitea container image (default: gitea/gitea:latest)"
	@echo "  ANSIBLE_ARGS           Extra arguments passed to ansible-playbook"

$(RUN_DIR):
	@mkdir -p $(RUN_DIR)

start-cmdb: $(RUN_DIR)
	@if [ -f $(CMDB_PIDFILE) ] && kill -0 $$(cat $(CMDB_PIDFILE)) 2>/dev/null; then \
		echo "CMDB already running (PID $$(cat $(CMDB_PIDFILE)))"; \
		exit 1; \
	fi
	@rm -f $(CMDB_PIDFILE)
	@$(PYTHON) $(HACK_DIR)/cmdb.py --host $(CMDB_HOST) --port $(CMDB_PORT) >>$(CMDB_LOG) 2>&1 & \
	echo $$! > $(CMDB_PIDFILE)
	@echo "Started CMDB (PID $$(cat $(CMDB_PIDFILE)), log: $(CMDB_LOG))"

stop-cmdb:
	@if [ ! -f $(CMDB_PIDFILE) ]; then \
		echo "CMDB is not running (no pidfile)"; \
		exit 0; \
	fi
	@pid=$$(cat $(CMDB_PIDFILE)); \
	if kill -0 $$pid 2>/dev/null; then \
		kill $$pid && echo "Stopped CMDB (PID $$pid)"; \
	else \
		echo "CMDB is not running (stale pidfile for PID $$pid)"; \
	fi
	@rm -f $(CMDB_PIDFILE)

start-ipam: $(RUN_DIR)
	@if [ -f $(IPAM_PIDFILE) ] && kill -0 $$(cat $(IPAM_PIDFILE)) 2>/dev/null; then \
		echo "IPAM already running (PID $$(cat $(IPAM_PIDFILE)))"; \
		exit 1; \
	fi
	@rm -f $(IPAM_PIDFILE)
	@$(PYTHON) $(HACK_DIR)/ipam.py --host $(IPAM_HOST) --port $(IPAM_PORT) >>$(IPAM_LOG) 2>&1 & \
	echo $$! > $(IPAM_PIDFILE)
	@echo "Started IPAM (PID $$(cat $(IPAM_PIDFILE)), log: $(IPAM_LOG))"

stop-ipam:
	@if [ ! -f $(IPAM_PIDFILE) ]; then \
		echo "IPAM is not running (no pidfile)"; \
		exit 0; \
	fi
	@pid=$$(cat $(IPAM_PIDFILE)); \
	if kill -0 $$pid 2>/dev/null; then \
		kill $$pid && echo "Stopped IPAM (PID $$pid)"; \
	else \
		echo "IPAM is not running (stale pidfile for PID $$pid)"; \
	fi
	@rm -f $(IPAM_PIDFILE)

start-gitea:
	@if $(CONTAINER_TOOL) inspect $(GITEA_CONTAINER) >/dev/null 2>&1; then \
		if [ "$$($(CONTAINER_TOOL) inspect -f '{{.State.Running}}' $(GITEA_CONTAINER))" = "true" ]; then \
			echo "Gitea already running (container $(GITEA_CONTAINER))"; \
			exit 1; \
		fi; \
		$(CONTAINER_TOOL) start $(GITEA_CONTAINER); \
		echo "Started existing Gitea container $(GITEA_CONTAINER) ($(GITEA_URL))"; \
	else \
		$(CONTAINER_TOOL) run -d \
			--name $(GITEA_CONTAINER) \
			-p $(GITEA_HTTP_PORT):3000 \
			-p $(GITEA_SSH_PORT):22 \
			-v $(GITEA_VOLUME):/data \
			$(GITEA_IMAGE); \
		echo "Started Gitea (container $(GITEA_CONTAINER), $(GITEA_URL), SSH port $(GITEA_SSH_PORT))"; \
	fi

stop-gitea:
	@if ! $(CONTAINER_TOOL) inspect $(GITEA_CONTAINER) >/dev/null 2>&1; then \
		echo "Gitea is not running (no container $(GITEA_CONTAINER))"; \
		exit 0; \
	fi
	@if [ "$$($(CONTAINER_TOOL) inspect -f '{{.State.Running}}' $(GITEA_CONTAINER))" = "true" ]; then \
		$(CONTAINER_TOOL) stop $(GITEA_CONTAINER) && echo "Stopped Gitea (container $(GITEA_CONTAINER))"; \
	else \
		echo "Gitea is not running (container $(GITEA_CONTAINER) exists but is stopped)"; \
	fi

start-services: start-cmdb start-ipam

stop-services: stop-cmdb stop-ipam

status:
	@if $(CONTAINER_TOOL) inspect $(GITEA_CONTAINER) >/dev/null 2>&1; then \
		if [ "$$($(CONTAINER_TOOL) inspect -f '{{.State.Running}}' $(GITEA_CONTAINER))" = "true" ]; then \
			echo "gitea: running (container $(GITEA_CONTAINER), $(GITEA_URL))"; \
		else \
			echo "gitea: not running (container $(GITEA_CONTAINER) exists but is stopped)"; \
		fi; \
	else \
		echo "gitea: not running"; \
	fi
	@for svc in cmdb ipam; do \
		pidfile="$(RUN_DIR)/$$svc.pid"; \
		if [ -f $$pidfile ] && kill -0 $$(cat $$pidfile) 2>/dev/null; then \
			echo "$$svc: running (PID $$(cat $$pidfile))"; \
		elif [ -f $$pidfile ]; then \
			echo "$$svc: not running (stale pidfile: $$(cat $$pidfile))"; \
		else \
			echo "$$svc: not running"; \
		fi; \
	done

run-playbook:
	$(ANSIBLE) -i $(INVENTORY) $(PLAYBOOK) \
		-e cmdb_url=$(CMDB_URL) \
		-e ipam_url=$(IPAM_URL) \
		$(ANSIBLE_ARGS)
