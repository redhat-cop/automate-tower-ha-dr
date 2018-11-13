#!/usr/bin/env python

import json
import subprocess
import os
import argparse
import logging
import yaml

ANS_INV_CMD = "ansible-inventory"
ANS_INV_ARGS = ["--list", "--export"]

# swap replica and master database
def _replica_to_master(inv):

    inv["database"]["hosts"], inv["database_replica"]["hosts"] = \
      inv["database_replica"]["hosts"], inv["database"]["hosts"]

    db = inv["database"]["hosts"][0]
    # determine if inventory hostname is used for connectivity
    if 'ansible_ssh_host' in inv["_meta"]["hostvars"][db]:
        db_host = inv["_meta"]["hostvars"][db]['ansible_ssh_host']
    else:
        db_host = db

    for h in inv["_meta"]["hostvars"].values():
        h["pg_host"] = db_host


# swap dr and primary hoss
def _dr_to_primary(inv):

    inv["tower"]["hosts"], inv["tower_dr"]["hosts"] = \
      inv["tower_dr"]["hosts"], inv["tower"]["hosts"]


def _get_inventory(inv_file):

    if not os.path.exists(inv_file):
        raise Exception("Inventory file does not exist")

    inv_cmd = [ANS_INV_CMD] + ["-i", inv_file] + ANS_INV_ARGS
    return json.loads(subprocess.check_output(inv_cmd))


def generate(replica_to_master=False, dr_to_primary=False, inventory_file='inventory'):

    inv = _get_inventory(inventory_file)
    if replica_to_master:
        _replica_to_master(inv)
    if dr_to_primary:
        _dr_to_primary(inv)

    # cleanup using ansible-inventory twice
    try:
        del inv['ungrouped']
        del inv['_meta']['ungrouped']
    except KeyError:
        pass

    return json.dumps(inv)


if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument('--list', action="store_true",
                    help="basic ansible inventory")

    parser.add_argument('--replica-to-master', action="store_true",
                    help="Swap master and replica.")

    parser.add_argument('--dr-to-primary', action="store_true",
                    help="Swap tower and tower_dr hosts")

    # parser.add_argument('--inventory-file', action="store",
    #                    help="Inventory file", default="./inventory_dr_static/inventory_pm")

    args = parser.parse_args()

    tower_inventory = {}

    if os.path.exists("vars_tower.yml"):
        with open("vars_tower.yml") as tv:
            tower_inventory = yaml.load(tv.read())

    if not os.path.exists('.tower_inventory.ini'):
        if tower_inventory:
            inventory_file = tower_inventory.get("tower_inventory_pm", None)
    else:
        with open('.tower_inventory.ini') as fh:
            inventory_file = fh.read()

        inventory_file = inventory_file.strip()

    print generate(args.replica_to_master, args.dr_to_primary, inventory_file)
