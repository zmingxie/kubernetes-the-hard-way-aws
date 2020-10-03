resource "random_id" "encryption_key" {
  byte_length = 32
}

locals {
  encryption_config = templatefile("${path.module}/templates/encryption-config.yaml.tmpl", {
    ENCRYPTION_KEY = random_id.encryption_key.b64_std
  })
}

resource "null_resource" "encryption_config" {
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
echo "${local.encryption_config}" > ./encryption-config.yaml
EOF
  }
}

# SCP encryption-config to each controller node
resource "null_resource" "controller_scp_encryption_config" {
  depends_on = [null_resource.encryption_config, null_resource.controller_scp_certs]
  count      = 3
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
scp -i kubernetes.id_rsa -o StrictHostKeyChecking=no \
  encryption-config.yaml \
  ubuntu@${aws_instance.kubernetes_controller[count.index].public_ip}:~/
EOF
  }
}
