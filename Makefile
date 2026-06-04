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

CMDB_PIDFILE := $(RUN_DIR)/cmdb.pid
IPAM_PIDFILE := $(RUN_DIR)/ipam.pid
CMDB_LOG := $(RUN_DIR)/cmdb.log
IPAM_LOG := $(RUN_DIR)/ipam.log

.PHONY: help start-cmdb stop-cmdb start-ipam stop-ipam start-services stop-services status run-playbook

.DEFAULT_GOAL := help

help:
	@echo "Mock API servers for Ansible VM GitOps testing"
	@echo ""
	@echo "Targets:"
	@echo "  make start-cmdb       Start CMDB in the background ($(CMDB_HOST):$(CMDB_PORT))"
	@echo "  make stop-cmdb        Stop CMDB using $(CMDB_PIDFILE)"
	@echo "  make start-ipam       Start IPAM in the background ($(IPAM_HOST):$(IPAM_PORT))"
	@echo "  make stop-ipam        Stop IPAM using $(IPAM_PIDFILE)"
	@echo "  make start-services   Start both CMDB and IPAM"
	@echo "  make stop-services    Stop both CMDB and IPAM"
	@echo "  make status           Show whether each service is running"
	@echo "  make run-playbook     Run $(PLAYBOOK) with cmdb_url and ipam_url"
	@echo ""
	@echo "Variables:"
	@echo "  CMDB_HOST, CMDB_PORT   CMDB bind address (default port: 8080)"
	@echo "  IPAM_HOST, IPAM_PORT   IPAM bind address (default port: 8081)"
	@echo "  CMDB_URL, IPAM_URL     URLs passed to the playbook as extra vars"
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

start-services: start-cmdb start-ipam

stop-services: stop-cmdb stop-ipam

status:
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
