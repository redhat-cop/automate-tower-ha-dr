
class FilterModule(object):
    ''' Ansible core jinja2 filters '''

    def filters(self):
        return {
            'infer_address' : self.infer_address
        }

    def infer_address(self, hostname, hostvars):

        for t in ('ansible_ssh_host', 'ansible_host', 'inventory_hostname'):
            if t in hostvars[hostname]:
                return hostvars[hostname][t]

        return None
