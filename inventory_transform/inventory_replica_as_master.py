#!/usr/bin/env python

import inventory_base
print inventory_base.generate(replica_to_master=True, dr_to_primary=False)
