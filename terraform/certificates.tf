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
  -cn=system:node:ip-10-0-1-2${count.index} \
  -hostname=ip-10-0-1-2${count.index},${aws_instance.kubernetes_worker[count.index].public_ip},${aws_instance.kubernetes_worker[count.index].private_ip} \
  -profile=kubernetes \
  worker-csr.json | cfssljson -bare worker-${count.index}
EOF
  }
}

# The Controller Manager Client Certificate
resource "null_resource" "kube_controller_manager_pem" {
  depends_on = [null_resource.ca_pem]
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
EOF
  }
}

# The Kube Proxy Client Certificate
resource "null_resource" "kube_proxy_pem" {
  depends_on = [null_resource.ca_pem]
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
EOF
  }
}

# The Scheduler Client Certificate
resource "null_resource" "kube_scheduler_pem" {
  depends_on = [null_resource.ca_pem]
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler
EOF
  }
}

# The Kubernetes API Server Certificate
resource "null_resource" "kube_api_pem" {
  depends_on = [null_resource.ca_pem]
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.0.1.10,10.0.1.11,10.0.1.12,${aws_lb.kubernetes_elb.dns_name},127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes
EOF
  }
}

# The Service Account Key Pair
resource "null_resource" "kube_sa_pem" {
  depends_on = [null_resource.ca_pem]
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account
EOF
  }
}

# Distribute server certs to controller nodes
resource "null_resource" "controller_scp" {
  depends_on = [null_resource.ca_pem, null_resource.kube_api_pem, null_resource.kube_sa_pem]
  count      = 3
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
echo "${tls_private_key.kubernetes.private_key_pem}" > ./kubernetes.id_rsa &&
chmod 600 kubernetes.id_rsa &&
scp -i kubernetes.id_rsa -o StrictHostKeyChecking=no \
  ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
  service-account-key.pem service-account.pem \
  ubuntu@${aws_instance.kubernetes_controller[count.index].public_ip}:~/
EOF
  }
}

# Distribute client certs to worker nodes
resource "null_resource" "worker_scp" {
  depends_on = [null_resource.ca_pem, null_resource.worker_pem]
  count      = 3
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
echo "${tls_private_key.kubernetes.private_key_pem}" > ./kubernetes.id_rsa &&
chmod 600 kubernetes.id_rsa &&
scp -i kubernetes.id_rsa -o StrictHostKeyChecking=no \
  ca.pem worker-${count.index}-key.pem worker-${count.index}.pem \
  ubuntu@${aws_instance.kubernetes_worker[count.index].public_ip}:~/
EOF
  }
}
