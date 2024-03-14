# #Script to deploy ec2 into a subnet, within a VPC and network interface

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


resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "main"
  }
     
}

resource "aws_internet_gateway" "custom_gw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "main"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom_gw.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.custom_vpc.id 
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
 

}


resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}


resource "aws_security_group" "vpc" {
 name        = "permission for VPC"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    from_port        = 80
    to_port          = 80 
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

   ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   }

    ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] 
    
  }

}


resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.main.id
  depends_on                = [aws_internet_gateway.custom_gw]
  associate_with_private_ip = "10.0.1.57"
}



















resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOljUMVeoE4DnxOiZwyECc19obQsYT0MJideH4U/I8cyvbHMiAx5QC9cavh7ak9DpEwogjKICXCBnljbHLm6/2xOiWkswZbVgUMn9ATbXbZhgestNcoAdY4LJwpF0T8QewYIuC2oHnCc3MHfK9KFjqSF8HDxv7tW6I/550rYChKj423uRBRm9sqbWKAzfvh+qQ1IHefQZ9vw7ilx9LVmW+RLaJLWxVvJhPUssB9DVXXqTVo8TkP8qtkjaKL2swXbbstCO6P1cnzGXbM/Nhmp1J7fiFIgvFjjA3HiiF+BUTEeNIZoyeaaAFcLMxeSevDQ99Dhad0UyJ4q2b7nO/VMefipEJ2MKdF7BBb6mjqSuSviw2UCY4Bu+M9bjZx2JPqEYI4uzsh/zCnEmgGX73WrHf9IOniPXdohiI1KLREsPaYJMoO9PckcipJPR4ZRJJUsCZECVDdpIYwyUkq0gwYLHcbqdBjbbKwF3koiZvWe/myq5eI3AWChmYV3yUYE49D6k= patri@DESKTOP-C1I06IV"
}


resource "aws_network_interface" "main" {
  subnet_id   = aws_subnet.public_subnet.id
  # public_ips = ["10.0.1.37"]
  private_ips     = ["10.0.1.57"]
  security_groups = [aws_security_group.vpc.id]

  tags = {
    name = "primary_network_interface"
  }
}

resource "aws_instance" "linux" {
  ami           = "ami-07d9b9ddc6cd8dd30" # us-west-2
  instance_type = "t2.micro"
  key_name = "deployer-key"
  

  network_interface {
    network_interface_id = aws_network_interface.main.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

tags = {

  name = "Linux"
}

  user_data = << EOF
  
  #!/bin/bash
  sudo apt update
  sudo apt upgrade
  sudo apt install apache2
  echo "<html> Hellow world </html>" > /var/www/html/index.html

  USERNAME = test
  
  sudo adduser $USERNAME

  sudo usermod -aG sudo $USERNAME

  #set user password

  EOF

}



