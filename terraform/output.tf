
output "kubernetes_public_address" {
  value = aws_lb.kubernetes_elb.dns_name
}

output "kubernetes_ec2_private_key" {
  value = tls_private_key.kubernetes.private_key_pem
}

output "kubernetes_controller_public_ip" {
  value = aws_instance.kubernetes_controller.*.public_ip
}

output "kubernetes_worker_public_ip" {
  value = aws_instance.kubernetes_worker.*.public_ip
}
