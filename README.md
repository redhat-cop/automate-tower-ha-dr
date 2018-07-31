High Level Workflow (Temporary)
================================

ASSUMPTIONS
- you've already provisioned the machines you're going to install on
- if you're not running as root and need to use privilege escalation (eg sudo) you need to set it up in the inventory (`ansible_become=true`)

1) Clone this repository.  In its current state is has the online Ansible Tower 3.2.5 installer inside.  I did not do any testing with the bundled installer.

2) Update the inventory_pm (primary/base inventory), inventory_ha (HA configuration inventory) and inventory_dr (DR configuration inventory) as appropriate.  The inventory_pm should contain only your primary cluster hosts and the databases you plan on replicating to. The inventory_dr should only contain your DR cluster hosts.  Only one HA ("local") database and one DR ("remote") database is supported.  These are identified by the pgsqlrep_type hostvar.  Make sure you get the right databases configured as primary and replicas in each inventory.

3) Run the Tower installer normally against your primary inventory `./setup.sh -i inventory_pm`

3.1) Run the playbook to ensure the samdoran.pgsql-replication roles is installed. `ansible-playbook tower_role_check.yml`.  If you don not have connectivity to github you'll need to download the tar archive and pass the path to the playbook, `ansible-playbook tower_role_check.yml -e replication_role_archive=ROLE_TGZ_ARCHIVE_LOCATION`

4) Run the the playbook to setup replication to the local and/or remote databases `ansible-playbook -i inventory_pm tower_setup_replication.yml`.  You can check the status of replication by running `ansible-playbook -i inventory_pm tower_check_replication.yml`

5) Run the script to prep the DR cluster for installation.  This will move the SECRET_KEY to the DR nodes. `./tower_dr_prep.sh -c inventory_pm -d inventory_dr`

You should now be ready to execute failover scenarios.

**HA failover**

NOTE: if you do not want to initialize replication back to the primary database and/or DR(remote) database you will need to remove them from the inventory. They can always be added later

To perform a HA failover, which will promote the HA/local replica database to primary and point Tower to it execute `./tower_pgsql_ha_failover.sh -c inventory_pm -a inventory_ha`

If the primary database has truly failed it can be redeployed/remediate/turned on and replication re-enabled so a "fail back" can occur but re-running `./tower_pgsql_ha_failover.sh -c inventory_pm -a inventory_ha`

One the primary database is fixe you can "fail back" to the original configuration by executing`./tower_pgsql_ha_failover.sh -c inventory_pm -a inventory_ha -b`.

**DR failover**

NOTE: if you do not want to initialize replication back to the primary database and/or HA(local) database you will need to remove them from the inventory.  They can always be added later

To perform a DR failover which will promote the DR/remote replication database to primary, run the tower installer against the DR nodes/newly promoted DR database and remove previous primary nodes execute `./tower_dr_failover.sh -c inventory_pm -d inventory_dr`

Once the primary cluster is repaired you should re-run the failover to setup to enable replication. `./tower_dr_failover.sh -c inventory_pm -d inventory_dr`

To "fail back" to the original configuration and primary cluster execute. `./tower_dr_failover.sh -c inventory_pm -d inventory_dr -b`

**Backup and Restore**

https://docs.ansible.com/ansible-tower/latest/html/administration/backup_restore.html#backup-and-restore-for-clustered-environments

**Other failovers**

If you want to do a DR failover from the HA failover configuration execute `./tower_dr_failover.sh -c inventory_ha -d inventory_dr`

**Why are you using bash scripts?**

Because people make mistakes when there are too many manual steps.  The shell scripts are simple, only run ansible scripts and can easily be teased apart into the individual playbook runs.



Ansible Tower Clustering/High Availability and Disaster Recover
===============================================================


**Clustering**

In addition to the base single node installation, Tower offers [clustered configurations](https://docs.ansible.com/ansible-tower/3.2.4/html/administration/clustering.html) to allow users to horizontally scale job capacity (forks) on nodes.  It is recommended to deploy tower nodes in odd numbers to prevent issues with underlying RabbitMQ clustering.

Tower clustering minimizes the potential of job execution service outages by distributing jobs across the cluster.
For example, if you have an Ansible Tower installation with a three node cluster configuration and the Ansible Tower services on a node become unavailable in the cluster, jobs will continue to be executed on the remaining two nodes.  It should be noted, the failed Ansible Tower node needs to remediated to return to a supported
configuration containing an odd number of nodes.  See [setup considerations] (https://docs.ansible.com/ansible-tower/latest/html/administration/clustering.html#setup-considerations)

Tower cluster nodes and database should be geographically co-located with low latency (<10 ms) and reliable connectivity.  Deployments that span datacenters are not recommended due to transient spikes in latency and/or outages.

**Database Availability**

Ansible Tower utilizes PostgreSQL for application level data storage.  The Tower setup process does not configure streaming replica configuration/hot standby configurations, which can be used for disaster recovery or high availability solutions.  Streaming replication can be enabled and configured as a Red Hat Consulting delivered solution.  The Tower database can be replicated to high availability instance in the local datacenter and/or to a disaster recovery instance in a remote datacenter.  The later being utilized in a disaster recovery scenario.  In the case of a failure in only the local database, the high availability instance can be promoted to a primary instance and the Tower cluster updated to utilize the instance.  In the case of a full primary datacenter outage, the disaster recovery instance can be promoted to a primary instance a new Tower cluster deployed and pointed to the instance.   

**Disaster Recovery**

As discussed above, Ansible Tower clusters can not span multiple datacenters and the default setup configuration does not support m






Ansible Tower Deployment
========================

This collection of files provides a complete set of playbooks for deploying
the Ansible Tower software to a single-server installation. It is also to
install Tower to the local machine, or to a remote machine reachable by SSH.

For quickly getting started with installation and setup instructions, refer to:

- Ansible Tower Quick Installation Guide -- http://docs.ansible.com/ansible-tower/latest/html/quickinstall/index.html
- Ansible Tower Quick Setup Guide -- http://docs.ansible.com/ansible-tower/latest/html/quickstart/index.html

For more indepth documentation, refer to:

- Ansible Tower Installation and Reference Guide -- http://docs.ansible.com/ansible-tower/latest/html/installandreference/index.html
- Ansible Tower User Guide -- http://docs.ansible.com/ansible-tower/latest/html/userguide/index.html
- Ansible Tower Administration Guide -- http://docs.ansible.com/ansible-tower/latest/html/administration/index.html
- Ansible Tower API Guide -- http://docs.ansible.com/ansible-tower/latest/html/towerapi/index.html

To install or upgrade, start by editing the inventory file in this directory.
Uncomment and change the password from 'password' for the 3 variables below.
* admin_password
* pg_password
* rabbitmq_password

Tower can be installed in 3 different modes:
1. On a single machine. This is the default, and will install in this mode with
   no modifications to the inventory file.
2. On a single machine with a remote PostgreSQL database. Supplying the pg_host
   and pg_port variables will trigger this mode of installation.
3. Cluster/High Availability, multiple machines with a remote PostgreSQL database.
   Adding multiple hosts to the [tower] inventory group will trigger this mode of
   installation. Note that pg_host and pg_port are also required.

Now you are ready to run ./setup.sh. Note that root access to the remote
machines is required. With Ansible, this can be achieved in many different.
Below are a few examples.
* ansible_ssh_user=root ansible_ssh_password="your_password_here" inventory
  host or group variables
* ansible_ssh_user=root ansible_ssh_private_key_file="path_to_your_keyfile.pem"
  inventory host or group variables
* ANSIBLE_BECOME_METHOD='sudo' ANSIBLE_BECOME=True ./setup.sh
* ANSIBLE_SUDO=True ./setup.sh

> *WARNING*: The playbook will overwrite the content
> of `pg_hba.conf` and strip all comments from `supervisord.conf`.  Run this
> only on a clean virtual machine if you are not ok with this behavior.
