#cloud-config

hostname: ${hostname}

keyboard:
  layout: fr

timezone: Europe/Paris

ssh_pwauth: false

users:
  - name: ${username}
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${ssh_public_key}