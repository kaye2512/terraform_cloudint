#cloud-config

hostname: ${hostname}
timezone: Europe/Paris
ssh_pwauth: false
package_update: true
package_upgrade: true
packages:
  - git
  - python3-pip

users:
  - name: ${username}
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${ssh_public_key}

  - name: ansible
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${ssh_public_key}

write_files:
  - path: /home/ansible/.ssh/id_ed25519
    owner: ansible:ansible
    permissions: '0600'
    defer: true
    content: |
      ${indent(6, github_ssh_private_key)}

  - path: /home/ansible/.ssh/id_ed25519.pub
    owner: ansible:ansible
    permissions: '0644'
    defer: true
    content: |
      ${indent(6, github_ssh_public_key)}

  - path: /home/ansible/.ssh/config
    owner: ansible:ansible
    permissions: '0600'
    defer: true
    content: |
      Host github.com
        User git
        IdentityFile ~/.ssh/id_ed25519
        IdentitiesOnly yes
        StrictHostKeyChecking accept-new

cloud_final_modules:
- package_update_upgrade_install
- write_files_deferred
- ansible
- scripts-user

ansible:
  package_name: ansible-core
  install_method: distro
  run_user: ansible
  pull:
    url: git@github.com:kaye2512/terraform_config_coud_init.git
    checkout: main
    playbook_name: site.yml
    accept_host_key: true
