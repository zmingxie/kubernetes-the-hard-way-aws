
output "kubernetes_public_address" {
  value = aws_lb.kubernetes_elb.dns_name
}

output "kubernetes_controller_public_ip" {
  value = aws_instance.kubernetes_controller[*].public_ip
}

output "kubernetes_worker_public_ip" {
  value = aws_instance.kubernetes_worker[*].public_ip
}
