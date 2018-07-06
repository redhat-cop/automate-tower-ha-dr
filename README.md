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
