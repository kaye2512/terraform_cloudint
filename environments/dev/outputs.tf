output "instance_public_ip" {
  description = "The public IP address of the instance"
  value       = module.compute.public_ip
}
