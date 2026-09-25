# terraform_cloudint

Infrastructure AWS en Terraform qui déploie une instance EC2 Debian 13 **auto-configurée au démarrage** grâce à **cloud-init** et **ansible-pull**.

Au premier boot, l'instance :

1. crée les utilisateurs et installe les paquets de base (cloud-init) ;
2. dépose les clés SSH nécessaires pour accéder à GitHub ;
3. récupère un dépôt de configuration Ansible ([`kaye2512/terraform_config_coud_init`](https://github.com/kaye2512/terraform_config_coud_init)) et exécute son playbook `site.yml` avec `ansible-pull`.

---

## Architecture

```
                    Internet
                       │
               ┌───────┴────────┐
               │ Internet GW    │
               └───────┬────────┘
┌──────────────────────┼──────────────────────────────┐
│ VPC 10.0.0.0/16      │                              │
│                      │  Route 0.0.0.0/0 → IGW       │
│   ┌──────────────────┴─────────────────────────┐    │
│   │ Subnet public 10.0.0.0/24 (eu-west-3a)     │    │
│   │                                            │    │
│   │   ┌──────────────────────────────┐         │    │
│   │   │ EC2 Debian 13 (t3.micro)     │         │    │
│   │   │ Security Group : SSH (22)    │         │    │
│   │   │ user-data : cloud-init       │         │    │
│   │   └──────────────────────────────┘         │    │
│   └────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

## Structure du projet

```
.
├── environments/
│   └── dev/                    # Racine Terraform de l'environnement "dev"
│       ├── main.tf             # Assemblage des modules network, security, compute
│       ├── provider.tf         # Provider AWS (~> 6.58.0)
│       ├── variables.tf        # Déclaration des variables
│       ├── terraform.tfvars.example  # Modèle à copier en terraform.tfvars (non versionné)
│       └── outputs.tf          # IP publique de l'instance
└── modules/
    ├── network/                # VPC, subnet public, Internet Gateway, routes
    ├── security/               # Security group (SSH entrant, tout sortant)
    └── compute/                # Instance EC2 + template cloud-init
        └── templates/
            └── user-data.tpl
```

## Modules

### `network`

| Ressource | Rôle |
|---|---|
| `aws_vpc.main` | VPC avec le CIDR `vpc_cidr_block` |
| `aws_internet_gateway.main` | Accès Internet du VPC |
| `aws_subnet.public` | Subnet `/24` (premier sous-réseau du VPC via `cidrsubnet(cidr, 8, 0)`) |
| `aws_route_table.public` + association | Route par défaut `0.0.0.0/0` vers l'IGW |
| `aws_route_table.private` | Table de routage privée (non utilisée pour l'instant) |

**Outputs :** `vpc_id`, `subnet_id`

### `security`

Security group `<environment>-sg` :
- **Entrant :** TCP 22 (SSH) depuis `ssh_allowed_cidr`
- **Sortant :** tout autorisé

**Output :** `security_group_id`

### `compute`

Instance EC2 `<environment>-instance` dont le `user_data` est généré à partir de `templates/user-data.tpl`.

**Outputs :** `instance_id`, `public_ip`

## Ce que fait cloud-init

Le template [`user-data.tpl`](modules/compute/templates/user-data.tpl) :

- définit le hostname et le fuseau horaire `Europe/Paris`, désactive l'authentification SSH par mot de passe ;
- met à jour le système et installe `git` et `python3-pip` ;
- crée deux utilisateurs sudo sans mot de passe, accessibles avec `ssh_public_key` :
  - `username` (par défaut `kaye`)
  - `ansible`
- écrit dans `/home/ansible/.ssh/` :
  - `id_ed25519` / `.pub` → clé utilisée pour `github.com`
  - `terraform_repo_id_ed25519` / `.pub` → clé utilisée pour l'alias `github.com-terraform`
  - un fichier `config` SSH qui associe chaque hôte à sa clé ;
- installe `ansible-core` et lance `ansible-pull` (en tant qu'utilisateur `ansible`) sur `git@github.com:kaye2512/terraform_config_coud_init.git`, branche `main`, playbook `site.yml`.

> Les clés GitHub doivent être enregistrées comme **deploy keys** (ou clés de compte) sur les dépôts concernés, sinon `ansible-pull` échouera.

## Variables

Définies dans [`environments/dev/variables.tf`](environments/dev/variables.tf).

| Variable | Description | Défaut |
|---|---|---|
| `aws_region` | Région AWS | `eu-west-3` (Paris) |
| `aws_access_key` / `aws_secret_key` | Identifiants AWS | *obligatoire* |
| `environment` | Nom de l'environnement (préfixe des ressources) | `dev` |
| `aws_ami` | AMI de l'instance | `ami-03dbc12aeff16b2d4` (Debian 13) |
| `instance_type` | Type d'instance EC2 | `t3.micro` |
| `vpc_cidr_block` | CIDR du VPC | `10.0.0.0/16` |
| `availability_zone` | Zone de disponibilité du subnet | `eu-west-3a` |
| `map_public_ip_on_launch` | IP publique automatique | `true` |
| `ssh_allowed_cidr` | CIDR autorisé en SSH | `0.0.0.0/0` |
| `ssh_public_key` | Clé publique pour se connecter à l'instance | *obligatoire* |
| `github_ssh_public_key` / `github_ssh_private_key` | Paire de clés pour le dépôt de configuration Ansible | *obligatoire* |
| `terraform_repo_ssh_public_key` / `terraform_repo_ssh_private_key` | Paire de clés pour l'alias `github.com-terraform` | *obligatoire* |
| `hostname` | Hostname de l'instance | `dev-instance` |
| `username` | Utilisateur principal créé sur l'instance | `kaye` |

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.x
- Un compte AWS avec des droits sur EC2 et VPC
- Une paire de clés SSH pour se connecter à l'instance
- Deux paires de clés ed25519 enregistrées sur GitHub pour les dépôts clonés par l'instance

Générer les clés :

```bash
ssh-keygen -t ed25519 -f ~/.ssh/github -C "ansible-pull"
```

```bash
ssh-keygen -t ed25519 -f ~/.ssh/terraform_repo -C "terraform-repo"
```

## Utilisation

1. Se placer dans l'environnement :

   ```bash
   cd environments/dev
   ```

2. Créer `terraform.tfvars` à partir de l'exemple et le remplir (voir la section [Sécurité](#sécurité) pour éviter d'y mettre les identifiants AWS) :

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Initialiser, planifier et appliquer :

   ```bash
   terraform init
   ```

   ```bash
   terraform plan
   ```

   ```bash
   terraform apply
   ```

4. Récupérer l'IP publique et se connecter :

   ```bash
   terraform output instance_public_ip
   ```

   ```bash
   ssh kaye@<IP_PUBLIQUE>
   ```

5. Suivre l'exécution de cloud-init / ansible-pull sur l'instance :

   ```bash
   sudo tail -f /var/log/cloud-init-output.log
   ```

6. Détruire l'infrastructure :

   ```bash
   terraform destroy
   ```

## Ajouter un environnement

Copier `environments/dev` vers `environments/staging` (ou `prod`), puis adapter `terraform.tfvars` (`environment`, `instance_type`, `ssh_allowed_cidr`, etc.). Les modules sont partagés entre tous les environnements.

