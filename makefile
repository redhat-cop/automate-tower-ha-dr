#!/usr/bin/make -f

ANSIBLE_PLAYBOOK := ansible-playbook
ANSIBLE_VERBOSITY := -vv
#ANSIBLE_KEY := '--private_key=~/.vagrant.d/insecure_private_key'
TOWER_FAILBACK_VARS := '-e tower_failback=1'

TOWER_VERSION ?= 3.6.3-1
TOWER_INVENTORY_DIR ?= inventory_ha_dr
TOWER_EL_VERSION ?= el7
VBOX ?= centos/7

ANSIBLE_EXTRA_VARS := "-e tower_version=$(TOWER_VERSION) -e tower_download=1 -e tower_bundle_version=$(TOWER_EL_VERSION)"

.PHONY: roles

#####INFRA
tower-infra-destroy:
	cd $(TOWER_INVENTORY_DIR); vagrant destroy -f

tower-infra-up-rh7: export VBOX=generic/rhel7
tower-infra-up-rh7: tower-infra-up
	@echo "END RH7 PROVISION"

tower-infra-up:
	cd $(TOWER_INVENTORY_DIR); VBOX=$(VBOX) vagrant up

##ANSIBLE
.PHONY: all test clean $(wildcard *.yml)

%:
	$(ANSIBLE_PLAYBOOK) $*.yml $(ANSIBLE_EXTRA_VARS) $(ANSIBLE_VERBOSITY) $(EF)

tower-dr-failback:
	@$(MAKE) tower-dr-failover EF=$(TOWER_FAILBACK_VARS)

tower-ha-failback:
	@$(MAKE) tower-ha-failover EF=$(TOWER_FAILBACK_VARS)

tower-orchestrate-full: tower-infra-up tower-setup tower-orchestrate-dr
	@echo "FINISHED TOWER INFRA + ORCHESTRATION"

tower-orchestrate-dr: tower-dr-standup tower-dr-failover tower-dr-failback
	@echo "FINISHED TOWER DR ORCHESTRATION"

tower-orchestrate-ha: tower-ha-standup tower-ha-failover tower-ha-failback
	@echo "FINISHED TOWER DA ORCHESTRATION"

###TOWER 3.6
tower-3.6-centos8: export VBOX=centos/8
tower-3.6-centos8: export TOWER_EL_VERSION=el8
tower-3.6-centos8: export TOWER_VERSION=3.6.3-1
tower-3.6-centos8:
	@$(MAKE) tower-orchestrate-full

tower-3.6-rh8: export VBOX=generic/rhel8
tower-3.6-rh8: export TOWER_EL_VERSION=el8
tower-3.6-rh8: export TOWER_VERSION=3.6.3-1
tower-3.6-rh8:
	@$(MAKE) tower-orchestrate-full

tower-3.6-centos7: export VBOX=centos/7
tower-3.6-centos7: export TOWER_EL_VERSION=el7
tower-3.6-centos7: export TOWER_VERSION=3.6.3-1
tower-3.6-centos7:
	@$(MAKE) tower-orchestrate-full

tower-3.6-rh7: export VBOX=generic/rhel7
tower-3.6-rh7: export TOWER_EL_VERSION=el7
tower-3.6-rh7: export TOWER_VERSION=3.6.3-1
tower-3.6-rh7:
	@$(MAKE) tower-orchestrate-full

###TOWER 3.5
tower-3.5-centos8: export VBOX=centos/8
tower-3.5-centos8: export TOWER_EL_VERSION=el8
tower-3.5-centos8: export TOWER_VERSION=3.5.4-1
tower-3.5-centos8:
	@$(MAKE) tower-orchestrate-full

tower-3.5-rh8: export VBOX=generic/rhel8
tower-3.5-rh8: export TOWER_EL_VERSION=el8
tower-3.5-rh8: export TOWER_VERSION=3.5.4-1
tower-3.5-rh8:
	@$(MAKE) tower-orchestrate-full

tower-3.5-centos7: export VBOX=centos/7
tower-3.5-centos7: export TOWER_EL_VERSION=el7
tower-3.5-centos7: export TOWER_VERSION=3.5.4-1
tower-3.5-centos7:
	@$(MAKE) tower-orchestrate-full

tower-3.5-rh7: export VBOX=generic/rhel7
tower-3.5-rh7: export TOWER_EL_VERSION=el7
tower-3.5-rh7: export TOWER_VERSION=3.5.4-1
tower-3.5-rh7:
	@$(MAKE) tower-orchestrate-full

