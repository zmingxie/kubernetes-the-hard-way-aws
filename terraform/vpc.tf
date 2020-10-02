# Internet VPC
resource "aws_vpc" "kubernetes" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "kubernetes"
  }
}

# resource "aws_vpc_dhcp_options" "kubernetes" {
#     domain_name = "eu-west-1.compute.internal"
#     domain_name_servers = ["AmazonProvidedDNS"]

#     tags {
#         Name = "kubernetes"
#     }
# }

# resource "aws_vpc_dhcp_options_association" "dns_resolver" {
#     vpc_id = "${aws_vpc.kubernetes.id}"
#     dhcp_options_id = "${aws_vpc_dhcp_options.kubernetes.id}"
# }

# Subnet
resource "aws_subnet" "kubernetes_public_subnet" {
  vpc_id     = aws_vpc.kubernetes.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "kubernetes-public-subnet"
  }
}

# Internet GW
resource "aws_internet_gateway" "kubernetes_gw" {
  vpc_id = aws_vpc.kubernetes.id

  tags = {
    Name = "kubernetes"
  }
}

resource "aws_route_table" "kubernetes_public" {
  vpc_id = aws_vpc.kubernetes.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubernetes_gw.id
  }

  tags = {
    Name = "kubernetes-public-route"
  }
}

resource "aws_route_table_association" "kubernetes_public_subnet" {
  subnet_id      = aws_subnet.kubernetes_public_subnet.id
  route_table_id = aws_route_table.kubernetes_public.id
}
