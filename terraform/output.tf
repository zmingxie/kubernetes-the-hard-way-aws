
output "kubernetes_public_address" {
  value = aws_lb.kubernetes_elb.dns_name
}
