locals {
  envname_tags = {
    stack = "shirwalab-multi-region-private-link"
  }

  producer_cidr            = "10.0.0.0/16"
  producer_azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  producer_private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  producer_public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  consumer_cidr            = "172.16.0.0/16"
  consumer_azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  consumer_private_subnets = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  consumer_public_subnets  = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]

  private_link_supported_regions = [
    "us-east-1",
    "eu-west-2",
  ]
}