#############################################################################
# Producer Account
##############################################################################

locals {
  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from the web server running on producer AWS account!</h1>" > /var/www/html/index.html
  EOT
}

module "producer_account_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v5.21.0"

  providers = {
    aws = aws.producer_account
  }

  name = "shirwalab-producer-account-vpc"
  cidr = local.producer_cidr

  azs             = local.producer_azs
  private_subnets = local.producer_private_subnets
  public_subnets  = local.producer_public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}

data "aws_ami" "al2023" {
  provider    = aws.producer_account
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

}

resource "aws_security_group" "web_sg" {
  provider = aws.producer_account

  name        = "web-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = module.producer_account_vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.producer_account_vpc.vpc_cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [module.producer_account_vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nlb_sg" {
  provider = aws.producer_account

  name        = "nlb-sg"
  description = "Allow HTTP"
  vpc_id      = module.producer_account_vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.producer_account_vpc.vpc_cidr_block]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.consumer_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "this" {
  provider = aws.producer_account

  name_prefix            = "shirwalab-producer-account-launch-template"
  image_id               = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  key_name               = "shirwa"
  user_data              = base64encode(local.user_data)
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "asg" {
  provider            = aws.producer_account
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = module.producer_account_vpc.private_subnets
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}

resource "aws_lb" "nlb" {
  provider                         = aws.producer_account
  name                             = "shirwalab-vpce-nlb"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = module.producer_account_vpc.private_subnets
  security_groups                  = [aws_security_group.nlb_sg.id]
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "nginx-tg" {
  provider = aws.producer_account

  name        = "nginx-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = module.producer_account_vpc.vpc_id
  target_type = "instance"
}

resource "aws_lb_listener" "listener" {
  provider = aws.producer_account

  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx-tg.arn
  }
}

resource "aws_autoscaling_attachment" "example" {
  provider               = aws.producer_account
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.nginx-tg.arn
}

resource "aws_vpc_endpoint_service" "endpoint_service" {
  provider                   = aws.producer_account
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.nlb.arn]
  supported_regions          = local.private_link_supported_regions
  allowed_principals         = ["arn:aws:iam::296673180777:root"]
  supported_ip_address_types = ["ipv4"]
  tags                       = { Name = "shirwalab-producer-account-vpce" }
}

