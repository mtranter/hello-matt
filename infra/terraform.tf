terraform {
  backend "s3" {
    bucket = "platform-in-a-box-tf-state"
    key    = "hello-matt/terraform.tfstate"
    region = "ap-southeast-2"
  }
}