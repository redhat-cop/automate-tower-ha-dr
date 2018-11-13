#!/usr/bin/env python

import json
import subprocess
import os
import argparse
import logging
import yaml

ANS_INV_CMD = "ansible-inventory"
ANS_INV_ARGS = ["--list", "--export"]


def _get_inventory(inv_file):

    if not os.path.exists(inv_file):
        raise Exception("Inventory file does not exist")

    inv_cmd = [ANS_INV_CMD] + ["-i", inv_file] + ANS_INV_ARGS
    inv = json.loads(subprocess.check_output(inv_cmd))

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

    parser.add_argument('--host', action="store",
                    help="basic ansible inventory")

    args = parser.parse_args()

    if os.path.exists("vars_tower.yml"):
        with open("vars_tower.yml") as tv:
            tower_inventory = yaml.load(tv.read())
    else:
        raise Exception("vars_tower.yml must be present & well-formed with inventory names")

    if not os.path.exists(tower_inventory.get("tower_inventory_pm", "EOF")):

        raise Exception("vars_tower.yml must contain a tower_inventory_pm file")

    if not os.path.exists(tower_inventory.get("tower_inventory_dr", "EOF")) and \
       not os.path.exists(tower_inventory.get("tower_inventory_ha", "EOF")):

        raise Exception("vars_tower.yml must contain a tower_inventory_dr or tower_inventory_ha file")

    if not os.path.exists('.tower_inventory.ini'):
        if tower_inventory:
            inventory_file = tower_inventory.get("tower_inventory_pm", None)
    else:
        with open('.tower_inventory.ini') as fh:
            inventory_file = fh.read()
            inventory_file = inventory_file.strip()

    if inventory_file not in [ v for k, v in tower_inventory.iteritems() if k.startswith("tower_inventory_") ]:
        raise Exception(".tower_inventory.ini does not contain a valid inventory.  Found " + inventory_file)

    print _get_inventory(inventory_file)
