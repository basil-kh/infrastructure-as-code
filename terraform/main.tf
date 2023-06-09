provider "aws" {
	region = "eu-west-1"
}


resource "aws_vpc" "tech230-basil-terraform-vpc" {
	cidr_block = "10.0.0.0/16"
	tags = {
		Name = "tech230-basil-terraform-vpc"
	}
}


resource "aws_internet_gateway" "tech230-basil-terra-IGW" {
	vpc_id = aws_vpc.tech230-basil-terraform-vpc.id
	tags = {
		Name = "tech230-basil-terra-IGW"
	}
}

resource "aws_subnet" "tech230-basil-app-public-subnet" {
	vpc_id            = aws_vpc.tech230-basil-terraform-vpc.id
	cidr_block        = "10.0.2.0/24"
	availability_zone = "eu-west-1a"
	map_public_ip_on_launch = true
	tags = {
		Name = "tech230-basil-app-public-subnet"
	}
}

resource "aws_subnet" "tech230-basil-DB-private-subnet" {
	vpc_id            = aws_vpc.tech230-basil-terraform-vpc.id
	cidr_block        = "10.0.3.0/24"
	availability_zone = "eu-west-1a"
	tags = {
		Name = "tech230-basil-DB-private-subnet"
	}
}

resource "aws_route_table" "tech230-basil-terra-Public-RT" {
	vpc_id = aws_vpc.tech230-basil-terraform-vpc.id
	route {
    	cidr_block = "0.0.0.0/0"
   		gateway_id = aws_internet_gateway.tech230-basil-terra-IGW.id
  }
	tags = {
		Name = "tech230-basil-terra-Public-RT"
	}
}

resource "aws_route_table_association" "tech230-basil-terra-rt-A" {
  route_table_id = aws_route_table.tech230-basil-terra-Public-RT.id
  subnet_id      = aws_subnet.tech230-basil-app-public-subnet.id
}

resource "aws_route" "tech230-basil-route" {
	route_table_id         = aws_route_table.tech230-basil-terra-Public-RT.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id             = aws_internet_gateway.tech230-basil-terra-IGW.id

}

resource "aws_security_group" "tech230-basil-terra-VPC-app-SG-80-22" {
	name        = "tech230-basil-terra-VPC-app-SG-80-22"
	description = "Allow SSH and HTTP traffic"
	vpc_id      = aws_vpc.tech230-basil-terraform-vpc.id
	tags = {
		Name = "tech230-basil-terra-VPC-app-SG-80-22"
	}

	ingress {
		from_port   = 22
		to_port     = 22
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port   = 80
		to_port     = 80
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "tech230-basil-terra-VPC-DB-SG-27017" {
	name        = "tech230-basil-terra-VPC-DB-SG-27017"
	description = "Allow MongoDB traffic on 27017"
	vpc_id      = aws_vpc.tech230-basil-terraform-vpc.id
	tags = {
		Name = "tech230-basil-terra-VPC-DB-SG-27017"
	}

	ingress {
		from_port   = 27017
		to_port     = 27017
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}



resource "aws_instance" "tech230-basil-terra-mongodb" {
	ami                    = "ami-09f9939f0890cfe4d"
	instance_type          = "t2.micro"
	vpc_security_group_ids = [aws_security_group.tech230-basil-terra-VPC-DB-SG-27017.id]
	subnet_id              = aws_subnet.tech230-basil-DB-private-subnet.id
	tags = {
		Name = "tech230-basil-terra-mongodb"
	}
	private_ip    = "10.0.3.10"
}

resource "time_sleep" "wait" {
  depends_on = [aws_instance.tech230-basil-terra-mongodb]

  create_duration = "30s"
}


resource "aws_instance" "tech230-basil-terra-app" {
	ami                    = "ami-0136ddddd07f0584f"
	instance_type          = "t2.micro"
	vpc_security_group_ids = [aws_security_group.tech230-basil-terra-VPC-app-SG-80-22.id]
	subnet_id              = aws_subnet.tech230-basil-app-public-subnet.id
	associate_public_ip_address = true
	key_name      = "tech230"
	tags = {
		Name = "tech230-basil-terra-app"
	}
	user_data = <<-EOF
    #!/bin/bash

	
  EOF
}