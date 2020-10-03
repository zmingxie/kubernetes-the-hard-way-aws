# kubeconfig for each worker node
resource "null_resource" "kubeconfig_worker" {
  depends_on = [null_resource.ca_pem, null_resource.worker_pem]
  count      = 3
  # FIXME: This could fail with an error like $HOME/.kube/config.lock exists
  #       This is because terraform tries to create all items in parallel.
  #       We should add the lock check here to avoid the error.
  #
  #       For now, a workaround would be running `terraform apply -parallelism=1`
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${aws_lb.kubernetes_elb.dns_name}:443 \
  --kubeconfig=worker-${count.index}.kubeconfig &&
kubectl config set-credentials system:node:worker-${count.index} \
  --client-certificate=worker-${count.index}.pem \
  --client-key=worker-${count.index}-key.pem \
  --embed-certs=true \
  --kubeconfig=worker-${count.index}.kubeconfig &&
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:node:worker-${count.index} \
  --kubeconfig=worker-${count.index}.kubeconfig &&
kubectl config use-context default --kubeconfig=worker-${count.index}.kubeconfig
EOF
  }
}

#  kube-proxy Configuration File
resource "null_resource" "kubeconfig_kube_proxy" {
  depends_on = [null_resource.ca_pem, null_resource.kube_proxy_pem, null_resource.kubeconfig_worker]
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${aws_lb.kubernetes_elb.dns_name}:443 \
  --kubeconfig=kube-proxy.kubeconfig &&
kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig &&
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig &&
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
EOF
  }
}

# The kube-controller-manager Kubernetes Configuration File
resource "null_resource" "kubeconfig_kube_controller_manager" {
  depends_on = [null_resource.ca_pem, null_resource.kube_controller_manager_pem, null_resource.kubeconfig_kube_proxy]
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig &&
kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig &&
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig &&
kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
EOF
  }
}

# The kube-scheduler Kubernetes Configuration File
resource "null_resource" "kubeconfig_kube_scheduler" {
  depends_on = [null_resource.ca_pem, null_resource.kube_scheduler_pem, null_resource.kubeconfig_kube_controller_manager]
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig &&
kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig &&
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig &&
kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
EOF
  }
}

# The admin Kubernetes Configuration File
resource "null_resource" "kubeconfig_admin" {
  depends_on = [null_resource.ca_pem, null_resource.admin_pem, null_resource.kubeconfig_kube_scheduler]
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig &&
kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig &&
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=admin \
  --kubeconfig=admin.kubeconfig &&
kubectl config use-context default --kubeconfig=admin.kubeconfig
EOF
  }
}

# Distribute the Kubernetes Configuration Files
resource "null_resource" "worker_scp_kubeconfig" {
  depends_on = [null_resource.kubeconfig_worker]
  count      = 3
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
scp -i kubernetes.id_rsa -o StrictHostKeyChecking=no \
  worker-${count.index}.kubeconfig kube-proxy.kubeconfig \
  ubuntu@${aws_instance.kubernetes_worker[count.index].public_ip}:~/
EOF
  }
}

resource "null_resource" "controller_scp_kubeconfig" {
  depends_on = [null_resource.kubeconfig_worker]
  count      = 3
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/certs &&
scp -i kubernetes.id_rsa -o StrictHostKeyChecking=no \
  admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig \
  ubuntu@${aws_instance.kubernetes_controller[count.index].public_ip}:~/
EOF
  }
}
