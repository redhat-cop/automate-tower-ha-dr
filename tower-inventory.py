#!/usr/bin/env python

import json
import subprocess
import os
import argparse
import yaml

TOWER_VARS_FILE = "tower-vars.yml"
TOWER_INV_INI_FILE = ".tower_inventory.ini"

# run ansible-inventory on the correct inventory file
def _get_inventory(inv_file):

    ANS_INV_CMD = "ansible-inventory"
    ANS_INV_ARGS = ["--list", "--export"]

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

    # append inventory read to all vars
    if 'vars' not in inv['all']:
        inv['all']['vars'] = {}

    inv['all']['vars']['tower_inventory_base'] = inv_file

    return json.dumps(inv)


def _get_inv_files(inv_path, tower_vars):
    tower_inventory_files = dict()
    tower_inventory_files['pm'] = dict(var_name='tower_inventory_pm', status=False)
    tower_inventory_files['ha'] = dict(var_name='tower_inventory_ha', status=False)
    tower_inventory_files['dr'] = dict(var_name='tower_inventory_dr', status=False)

    for config, data in tower_inventory_files.items():
        curr_inv_file = os.path.join(inv_path, tower_vars.get(data['var_name'],'__UNDEFINED__'))
        if os.path.exists(curr_inv_file):
            tower_inventory_files[config]['location'] = curr_inv_file
            tower_inventory_files[config]['status'] = True

    return tower_inventory_files


if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument('--list', action="store_true",
                    help="basic ansible inventory")

    parser.add_argument('--host', action="store",
                    help="basic ansible inventory")

    args = parser.parse_args()

    # assume inventory and vars files are at same path
    inv_path = os.path.dirname(os.path.abspath(__file__))

    # load tower vars file with info about failover configurations
    vars_tower_file = os.path.join(inv_path, TOWER_VARS_FILE)
    if os.path.exists(vars_tower_file):
        with open(vars_tower_file) as tv:
            tower_vars = yaml.load(tv.read(), Loader=yaml.Loader)
    else:
        raise Exception(vars_tower_file + " must be present and well-formed YAML")

    tower_inventory_files = _get_inv_files(inv_path, tower_vars)

    # ensure tower vars file has a primary inventory file
    if not tower_inventory_files['pm']['status']:
        raise Exception(vars_tower_file + " must contain a tower_inventory_pm file")

    # ensure tower vars file has a ha and/or dr inventory file
    if not tower_inventory_files['ha']['status'] and not tower_inventory_files['dr']['status']:
        raise Exception(vars_tower_file + " must contain a tower_inventory_dr or tower_inventory_ha file")

    # ini file contents are used to determine which inventory file to load
    inv_ini_path = os.path.join(inv_path, TOWER_INV_INI_FILE)

    # default to primary
    if not os.path.exists(inv_ini_path):
        if tower_vars:
            inventory_file = tower_inventory_files['pm']['location']
    else:
        with open(inv_ini_path) as fh:
            inventory_file = fh.read()
            inventory_file = inventory_file.strip()
            inventory_file = os.path.join(inv_path, inventory_file)

    print(_get_inventory(inventory_file))
