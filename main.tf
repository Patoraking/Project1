#Script to deploy ec2 into a subnet, within a VPC and network interface

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.39.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}


resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0/16"
     
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id 
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"


}

resource "aws_network_interface" "main" {
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["10.0.1.30"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "linux" {
  ami           = "ami-07d9b9ddc6cd8dd30" # us-west-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.main.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}

 
resource "aws_internet_gateway_attachment" "main" {
  internet_gateway_id = aws_internet_gateway.main.id
  vpc_id              =  aws_vpc.my_vpc.id
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "main"
  }
}