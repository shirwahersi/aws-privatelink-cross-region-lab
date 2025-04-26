#############################################################################
# Consumer Account
##############################################################################

module "consumer_account_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v5.21.0"

  providers = {
    aws = aws.consumer_account
  }

  name                   = "shirwalab-consumer-account-vpc"
  cidr                   = local.consumer_cidr
  azs                    = local.consumer_azs
  private_subnets        = local.consumer_private_subnets
  public_subnets         = local.consumer_public_subnets
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}


resource "aws_security_group" "consumer_vpce_sg" {
  provider = aws.consumer_account

  name        = "consumer_vpce_sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = module.consumer_account_vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.consumer_account_vpc.vpc_cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [module.consumer_account_vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "consumer_vpc_endpoints" {
  provider = aws.consumer_account

  vpc_id              = module.consumer_account_vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = aws_vpc_endpoint_service.endpoint_service.service_name
  subnet_ids          = module.consumer_account_vpc.private_subnets
  security_group_ids  = [aws_security_group.consumer_vpce_sg.id]
  service_region      = "us-east-1"
  private_dns_enabled = false

  tags = {
    Name = "shirwalab-consumer-vpc-endpoint"
  }
}