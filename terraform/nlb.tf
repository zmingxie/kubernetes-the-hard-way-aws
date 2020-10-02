resource "aws_lb" "kubernetes_elb" {
  name               = "kubernetes"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.kubernetes_public_subnet.id]

  tags = {
    Name = "kubernetes"
  }
}

resource "aws_lb_target_group" "kubernetes_tg" {
  name        = "kubernetes"
  port        = 6443
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.kubernetes.id
}

resource "aws_lb_target_group_attachment" "k8s_tg_target1" {
  target_group_arn = aws_lb_target_group.kubernetes_tg.arn
  target_id        = "10.0.1.10"
}

resource "aws_lb_target_group_attachment" "k8s_tg_target2" {
  target_group_arn = aws_lb_target_group.kubernetes_tg.arn
  target_id        = "10.0.1.11"
}

resource "aws_lb_target_group_attachment" "k8s_tg_target3" {
  target_group_arn = aws_lb_target_group.kubernetes_tg.arn
  target_id        = "10.0.1.12"
}

resource "aws_lb_listener" "kubernetes" {
  load_balancer_arn = aws_lb.kubernetes_elb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kubernetes_tg.arn
  }
}
