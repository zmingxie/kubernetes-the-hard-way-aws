
data "aws_ami" "ubuntu_2004" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  owners = ["099720109477"]
}

resource "tls_private_key" "kubernetes" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "kubernetes_key" {
  key_name   = "kubernetes-key"
  public_key = tls_private_key.kubernetes.public_key_openssh
}

resource "aws_instance" "kubernetes_controller" {
  key_name                    = aws_key_pair.kubernetes_key.key_name
  ami                         = data.aws_ami.ubuntu_2004.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.kubernetes_public_subnet.id
  associate_public_ip_address = true
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.kubernetes_sg.id]

  count      = 3
  private_ip = "10.0.1.1${count.index}"
  user_data  = "name=controller-${count.index}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
  }

  tags = {
    Name = "kubernetes-controller-${count.index}"
  }

}

resource "aws_instance" "kubernetes_worker" {
  key_name                    = aws_key_pair.kubernetes_key.key_name
  ami                         = data.aws_ami.ubuntu_2004.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.kubernetes_public_subnet.id
  associate_public_ip_address = true
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.kubernetes_sg.id]

  count      = 3
  private_ip = "10.0.1.2${count.index}"
  user_data  = "name=worker-${count.index}|pod-cidr=10.200.${count.index}.0/24"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
  }

  tags = {
    Name = "kubernetes-worker-${count.index}"
  }

}
