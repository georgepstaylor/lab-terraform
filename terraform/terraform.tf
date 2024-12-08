terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "2.1.2"
    }
  }
  required_version = "~> 1.7"

  backend "s3" {
    key                         = "terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
  /*
      ENVIRONMENT VARIABLES
      ---------------------
      AWS_ACCESS_KEY_ID     - R2 token
      AWS_SECRET_ACCESS_KEY - R2 secret
      AWS_ENDPOINT_URL_S3   - R2 location: https://ACCOUNT_ID.r2.cloudflarestorage.com
    */

}

provider "cloudflare" {
  # token and email are set in the environment vars
  # `CLOUDFLARE_EMAIL` and `CLOUDFLARE_API_TOKEN` respectively
}

provider "aws" {
  region = "eu-west-2"
}

provider "onepassword" {
  # OP_SERVICE_ACCOUNT_TOKEN is set in the environment var `OP_SERVICE_ACCOUNT_TOKEN`
}
