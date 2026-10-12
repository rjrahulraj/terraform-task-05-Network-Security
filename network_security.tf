locals {
  common_tags = {
    Project = var.project_id
  }
}
data "aws_instance" "public" {
  instance_id = var.public_instance_id
}

data "aws_instance" "private" {
  instance_id = var.private_instance_id
}

data "aws_network_interfaces" "public" {
  filter {
    name   = "attachment.instance-id"
    values = [var.public_instance_id]
  }
}

data "aws_network_interfaces" "private" {
  filter {
    name   = "attachment.instance-id"
    values = [var.private_instance_id]
  }
}


resource "aws_security_group" "ssh" {
  name        = "${var.project_id}-ssh-sg"
  description = "Allow SSH and ICMP from approved IP ranges"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}

resource "aws_security_group" "public_http" {
  name        = "${var.project_id}-public-http-sg"
  description = "Allow public HTTP and ICMP from approved IP ranges"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}

resource "aws_security_group" "private_http" {
  name        = "${var.project_id}-private-http-sg"
  description = "Allow HTTP and ICMP from the public HTTP security group"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}


# SSH security group: SSH from approved IP ranges
resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.ssh.id
  description       = "Allow SSH from approved IP ranges"

  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = var.allowed_ip_range
}


# SSH security group: all ICMP from approved IP ranges
resource "aws_security_group_rule" "ssh_icmp_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.ssh.id
  description       = "Allow all ICMP from approved IP ranges"

  protocol    = "icmp"
  from_port   = -1
  to_port     = -1
  cidr_blocks = var.allowed_ip_range
}


# Public HTTP security group: HTTP from approved IP ranges
resource "aws_security_group_rule" "public_http_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.public_http.id
  description       = "Allow HTTP from approved IP ranges"

  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = var.allowed_ip_range
}


# Public HTTP security group: all ICMP from approved IP ranges
resource "aws_security_group_rule" "public_http_icmp_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.public_http.id
  description       = "Allow all ICMP from approved IP ranges"

  protocol    = "icmp"
  from_port   = -1
  to_port     = -1
  cidr_blocks = var.allowed_ip_range
}


# Private HTTP security group: HTTP from public HTTP SG
resource "aws_security_group_rule" "private_http_ingress" {
  type                     = "ingress"
  security_group_id        = aws_security_group.private_http.id
  description              = "Allow HTTP 8080 from public HTTP SG"
  protocol                 = "tcp"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.public_http.id
}

# Private HTTP security group: all ICMP from public HTTP SG
resource "aws_security_group_rule" "private_http_icmp_ingress" {
  type                     = "ingress"
  security_group_id        = aws_security_group.private_http.id
  description              = "Allow all ICMP from public HTTP SG"
  protocol                 = "icmp"
  from_port                = -1
  to_port                  = -1
  source_security_group_id = aws_security_group.public_http.id
}

# Public instance attachments

# Attach SSH SG to public instance
resource "aws_network_interface_sg_attachment" "public_ssh" {
  security_group_id    = aws_security_group.ssh.id
  network_interface_id = data.aws_network_interfaces.public.ids[0]
}

# Attach public HTTP SG to public instance
resource "aws_network_interface_sg_attachment" "public_http" {
  security_group_id    = aws_security_group.public_http.id
  network_interface_id = data.aws_network_interfaces.public.ids[0]
}

# Private instance attachments

# Attach SSH SG to private instance
resource "aws_network_interface_sg_attachment" "private_ssh" {
  security_group_id    = aws_security_group.ssh.id
  network_interface_id = data.aws_network_interfaces.private.ids[0]
}

# Attach private HTTP SG to private instance
resource "aws_network_interface_sg_attachment" "private_http" {
  security_group_id    = aws_security_group.private_http.id
  network_interface_id = data.aws_network_interfaces.private.ids[0]
}