output "instance_hostname" {
  description = "DNS publique de l'instance EC2"
  value       = module.compute.instance_public_dns
}
