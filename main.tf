#################################
##			Variables		   ##
#################################
variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-east-2"
}
variable "vpc_name" {
  type        = "string"
  description = "Enter a Name for the VPC."
}
variable "vpc_description" {
  description = "Enter a friendly description for this VPC"
}
variable "cidr_block" {
  description = "Enter your CIDR block for the VPC.  Example: 10.150.0.0/16"
  default = "10.0.0.0/16"
}

#################################
##			Provider		   ##
#################################
provider "aws" {
	region = "${var.region}"
	access_key = "${var.access_key}"
	secret_key = "${var.secret_key}"
}

data "aws_availability_zones" "all" {}
	
#################################
##			  VPC			   ##
#################################
resource "aws_vpc" "main" {
	cidr_block = "${var.cidr_block}"
	tags {
	instance_tenancy     = "default"
	enable_dns_support   = "true"
	enable_dns_hostnames = "true"
	}
	
	tags = {
		Name        = "${var.vpc_name}"
		Description = "${var.vpc_description}"
	}
	
	lifecycle {
		create_before_destroy = true
	}
}

#################################
##		Public Subnets		   ##
#################################
### Create Public Subnet 1 in AZ1
resource "aws_subnet" "public_subnet_az1" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${cidrsubnet("${var.cidr_block}", 10, 3)}"
  availability_zone = "${data.aws_availability_zones.all.names[0]}"

  tags = {
    Name = "${aws_vpc.main.id}-public-subnet-az1"
  }
}

### Associate Public Subnet 1 to Public Route Table
resource "aws_route_table_association" "public_1" {
  subnet_id      = "${aws_subnet.public_subnet_az1.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}
	
#################################
##		Private Subnets		   ##
#################################
### Create Private Subnet for NAT Gateway 1 in AZ1
resource "aws_subnet" "nat_subnet_az1" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${cidrsubnet("${var.cidr_block}", 12, 4076)}"
  availability_zone = "${data.aws_availability_zones.all.names[0]}"

  tags = {
    Name = "${aws_vpc.main.id}-NatGatewayPublicSubnet1"
  }
}

resource "aws_route_table_association" "nat_gw_1" {
  subnet_id      = "${aws_subnet.nat_subnet_az1.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

#################################
##		  Internet Gateway     ##
#################################
resource "aws_internet_gateway" "internet" {
	vpc_id = "${aws_vpc.main.id}"
	tags = {
	Name = "${aws_vpc.main.id}-internet_gateway"
	}
	lifecycle {
		create_before_destroy = true
	}
}

#################################
##	  Public Routing Table     ##
#################################
### Create Public Route Table for VPC
resource "aws_route_table" "public_route_table" {
	vpc_id = "${aws_vpc.main.id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.internet.id}"
	}

	tags = {
		Name = "${aws_vpc.main.id}-PublicRouteTable"
	}
}

#################################
##	  Private Routing Table    ##
#################################
### Create Private Route Table for VPC for AZ1
resource "aws_route_table" "private_route_table_az1" {
	vpc_id = "${aws_vpc.main.id}"

	tags = {
		Name = "${aws_vpc.main.id}-PrivateRouteTable-AZ1"
	}
}

### Create Private Route Table for VPC for AZ2
resource "aws_route_table" "private_route_table_az2" {
	vpc_id = "${aws_vpc.main.id}"

	tags = {
		Name = "${aws_vpc.main.id}-PrivateRouteTable-AZ2"
	}	
}

### Create Private Route Table for VPC for AZ3
resource "aws_route_table" "private_route_table_az3" {
	vpc_id = "${aws_vpc.main.id}"

	tags = {
		Name = "${aws_vpc.main.id}-PrivateRouteTable-AZ3"
  }
}

#################################
##		   Security Group  ##
#################################
resource "aws_security_group" "main" {
	name = "${aws_vpc.main.id}-SecurityGroup"
	vpc_id = "${aws_vpc.main.id}"
	ingress {
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}	
	lifecycle {
		create_before_destroy = true
	}
}
