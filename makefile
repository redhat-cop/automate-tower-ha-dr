#!/usr/bin/make -f

ANSIBLE_PLAYBOOK := ansible-playbook

ANSIBLE_VERBOSITY := -vv
#ANSIBLE_KEY := '--private_key=~/.vagrant.d/insecure_private_key'
TOWER_FAILBACK_VARS := '-e tower_failback=1'

TOWER_VERSION ?= 3.6.3-1
TOWER_INVENTORY_DIR ?= inventory_ha_dr
TOWER_EL_VERSION ?= el7
VBOX ?= centos/7

VMEM ?=16384
VCPU ?= 4

ANSIBLE_EXTRA_VARS := "-e tower_version=$(TOWER_VERSION) -e tower_download=1"

.PHONY: roles

#####INFRA
tower-infra-destroy:
	cd $(TOWER_INVENTORY_DIR); VBOX=$(VBOX) vagrant destroy -f

tower-infra-up-rh7: export VBOX=generic/rhel7
tower-infra-up-rh7: tower-infra-up
	@echo "END RH7 PROVISION"

tower-infra-up:
	cd $(TOWER_INVENTORY_DIR); VBOX=$(VBOX) VMEM=$(VMEM) VCPU=$(VCPU) vagrant up

##ANSIBLE
.PHONY: all test clean $(wildcard *.yml)

%:
	$(ANSIBLE_PLAYBOOK) $*.yml $(ANSIBLE_EXTRA_VARS) $(ANSIBLE_VERBOSITY) $(EF)

tower-dr-failback:
	@$(MAKE) tower-dr-failover EF=$(TOWER_FAILBACK_VARS)

tower-ha-failback:
	@$(MAKE) tower-ha-failover EF=$(TOWER_FAILBACK_VARS)

tower-base-setup: tower-infra-up tower-setup
	@echo "FINISHED TOWER INFRA + ORCHESTRATION"

tower-orchestrate-dr: tower-base-setup tower-dr-standup tower-dr-failover tower-dr-failback
	@echo "FINISHED TOWER DR ORCHESTRATION"

tower-orchestrate-ha: tower-base-setup tower-ha-standup tower-ha-failover tower-ha-failback
	@echo "FINISHED TOWER DA ORCHESTRATION"

###TOWER 3.6 CentOS 8
tower-3.6-centos8-dr:
	@$(MAKE) VBOX=centos/8 TOWER_EL_VERSION=el8 TOWER_VERSION=3.6.3-1 tower-orchestrate-dr

tower-3.6-centos8-ha:
	@$(MAKE) VBOX=centos/8 TOWER_EL_VERSION=el8 TOWER_VERSION=3.6.3-1 tower-orchestrate-ha

###TOWER 3.6 RHEL 8
tower-3.6-rh8-dr:
	@$(MAKE) VBOX=generic/rhel8 TOWER_EL_VERSION=el8 TOWER_VERSION=3.6.3-1 tower-orchestrate-dr

tower-3.6-rh8-ha:
	@$(MAKE) VBOX=generic/rhel8 TOWER_EL_VERSION=el8 TOWER_VERSION=3.6.3-1 tower-orchestrate-ha

###TOWER 3.6 CentOS 7
tower-3.6-centos7-dr:
	@$(MAKE) VBOX=centos/7 TOWER_EL_VERSION=el7 TOWER_VERSION=3.6.3-1 tower-orchestrate-dr

tower-3.6-centos7-ha:
	@$(MAKE) VBOX=centos/7 TOWER_EL_VERSION=el7 TOWER_VERSION=3.6.3-1 tower-orchestrate-ha

###TOWER 3.6 RHEL 7
tower-3.6-rh7-dr:
	@$(MAKE) VBOX=generic/rhel7 TOWER_EL_VERSION=el7 TOWER_VERSION=3.6.3-1 tower-orchestrate-dr

tower-3.6-rh7-ha:
	@$(MAKE) VBOX=generic/rhel7 TOWER_EL_VERSION=el7 TOWER_VERSION=3.6.3-1 tower-orchestrate-ha

###TOWER 3.5 centos 8
tower-3.5-centos8-dr:
	@$(MAKE) VBOX=centos/8 TOWER_EL_VERSION=el8 TOWER_VERSION=3.5.4-1 tower-orchestrate-dr

tower-3.5-centos8-ha:
	@$(MAKE) VBOX=centos/8 TOWER_EL_VERSION=el8 TOWER_VERSION=3.5.4-1 tower-orchestrate-ha

###TOWER 3.5 RHEL 8
tower-3.5-rh8-dr:
	@$(MAKE) VBOX=generic/rhel8 TOWER_EL_VERSION=el8 TOWER_VERSION=3.5.4-1 tower-orchestrate-dr

tower-3.5-rh8-ha:
	@$(MAKE) VBOX=generic/rhel8 TOWER_EL_VERSION=el8 TOWER_VERSION=3.5.4-1 tower-orchestrate-ha

###TOWER 3.5 centos 7
tower-3.5-centos7-dr:
	@$(MAKE) VBOX=centos/7 TOWER_EL_VERSION=el7 TOWER_VERSION=3.5.4-1 tower-orchestrate-dr

tower-3.5-centos7-ha:
	@$(MAKE) VBOX=centos/7 TOWER_EL_VERSION=el7 TOWER_VERSION=3.5.4-1 tower-orchestrate-ha

###TOWER 3.5 RHEL 7
tower-3.5-rh7-dr:
	@$(MAKE)  VBOX=generic/rhel7 TOWER_EL_VERSION=el7 TOWER_VERSION=3.5.4-1 tower-orchestrate-dr

tower-3.5-rh7-ha:
	@$(MAKE)  VBOX=generic/rhel7 TOWER_EL_VERSION=el7 TOWER_VERSION=3.5.4-1 tower-orchestrate-ha
