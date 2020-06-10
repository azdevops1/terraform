#################################
##			Variables		   ##
#################################
variable "access_key" {}
variable "secret_key" {}


#################################
##			Provider		   ##
#################################
provider "aws" {
	region = "us-west-1"
	access_key = "${var.access_key}"
	secret_key = "${var.secret_key}"
}

resource "aws_instance" "example" {
  ami           = "ami-0b91a410940e82c54"
  instance_type = "t2.micro"
}

resource "aws_instance" "second_example" {
  ami           = "ami-0b91a410940e82c54"
  instance_type = "t2.micro"
}
