provider "aws" {
  alias   = "producer_account"
  profile = "producer_account"
  region  = "us-east-1"
  default_tags {
    tags = local.envname_tags
  }
}

provider "aws" {
  alias   = "consumer_account"
  profile = "consumer_account"
  region  = "eu-west-2"
  default_tags {
    tags = local.envname_tags
  }
}