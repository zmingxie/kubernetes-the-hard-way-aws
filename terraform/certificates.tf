# Certificate Authority
resource "null_resource" "ca_pem" {
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
EOF
  }
}

# The Admin Client Certificate
resource "null_resource" "admin_pem" {
  depends_on = [null_resource.ca_pem]
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
EOF
  }
}

# The Kubelet Client Certificates
resource "null_resource" "worker_pem" {
  depends_on = [null_resource.ca_pem]
  count      = 3
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -cn=system:node:ip-10-0-1-2${count.index}
  -hostname=ip-10-0-1-2${count.index},${aws_instance.kubernetes_worker[count.index].public_ip},${aws_instance.kubernetes_worker[count.index].private_ip} \
  -profile=kubernetes \
  worker-csr.json | cfssljson -bare worker-${count.index}
EOF
  }
}
