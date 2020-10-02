resource "aws_security_group" "kubernetes_sg" {
  vpc_id      = aws_vpc.kubernetes.id
  name        = "kubernetes-sg"
  description = "Kubernetes security group"

  tags = {
    Name = "kubernetes-sg"
  }
}

resource "aws_security_group_rule" "allow_all_internal_nodes" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_blocks       = ["10.0.0.0/16"]
}

resource "aws_security_group_rule" "allow_all_internal_pods" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_blocks       = ["10.200.0.0/16"]
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.kubernetes_sg.id
<<<<<<< HEAD
  # cidr_blocks       = ["0.0.0.0/0"]
  cidr_blocks       = ["69.165.242.100/32"]
=======
  cidr_blocks       = ["0.0.0.0/0"]
>>>>>>> 69588aa... Fixup
}

resource "aws_security_group_rule" "allow_ingress_6443" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_icmp" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outgoing" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.kubernetes_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}
