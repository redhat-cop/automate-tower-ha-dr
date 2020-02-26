#!/usr/bin/make -f

AP := ansible-playbook
TOWER_VERSION := 3.6.3-1
TOWER_EL_VERSION := el7

AG := "-e tower_version=$(TOWER_VERSION) -e tower_download=1 -e tower_bundle_version=$(TOWER_EL_VERSION)"
AV := -vv
#AK := '--private_key=~/.vagrant.d/insecure_private_key'
AF := '-e tower_failback=1'

AI := inventory_ha_dr

.PHONY: roles

#####INFRA
tower-infra-destroy:
	cd $(AI); vagrant destroy -f

tower-infra-up:
	cd $(AI); vagrant up

##ANSIBLE
.PHONY: all test clean $(wildcard *.yml)

%:
	$(AP) $*.yml $(AG) $(AV) $(EF)

tower-dr-failback:
	@$(MAKE) tower-dr-failover EF=$(AF)

tower-ha-failback:
	@$(MAKE) tower-ha-failover EF=$(AF)

tower-orchestrate-full: tower-infra-up tower-setup tower-orchestrate-dr

tower-orchestrate-dr: tower-dr-standup tower-dr-failover tower-dr-failback tower-ha-failover tower-ha-failback

tower-3.5:
	@$(MAKE) tower-orchestrate-full TOWER_VERSION=3.5.4-1

tower-3.6:
	@$(MAKE) tower-orchestrate-full TOWER_VERSION=3.6.3-1

tower-3.6-el7:
	@$(MAKE) tower-3.6 TOWER_EL_VERSION=el7

tower-3.6-el8:
	@$(MAKE) tower-3.6 TOWER_EL_VERSION=el8

tower-3.5-el7:
	@$(MAKE) tower-3.5 TOWER_EL_VERSION=el8

tower-3.5-el8:
	@echo "not supported"
	
