terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "2.2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "2.1.2"
    }
  }
}
