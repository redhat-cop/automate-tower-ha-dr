
# The system UUID, as captured by Ansible.
SYSTEM_UUID = '{% if system_uuid|skipped %}{{ ansible_product_uuid.lower() }}{% else %}{{ system_uuid.stdout.strip() }}{% endif %}'
