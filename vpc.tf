#varibles (please change config.tfvars)

variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "instance_type" {}
variable "vpc_name" {}
variable "cidr_block" {}
variable "public_ranges" {}
variable "private_ranges" {}
#Define Cloud Provider
variable "amis" {
  type = "map"
}
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}


#Creating the VPC 

resource "aws_vpc" "vpc" {
  cidr_block       = "${var.cidr_block}"

  tags {
    Name = "${var.vpc_name}"
  }
}


#Creating Public Subnet
resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "${var.public_ranges}"
  map_public_ip_on_launch = "true"

    tags {
        Name = "${var.vpc_name} ${var.region} public"
}
}



#Creating Private Subnet
resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "${var.private_ranges}"

  tags {
    Name = "${var.vpc_name} ${var.region} private"
  }
}


#Creating Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.vpc_name} IGW"
  }
}

#Creating EIP for NAT Gateway
resource "aws_eip" "nat" {
  vpc = true
}


#Creating NAT Gateway
resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public.id}"


  tags {
    Name = "${var.vpc_name} NatGateway"
  }
}

#Creating Public Route table
resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.vpc.id}"

    tags { 
        Name = "${var.vpc_name} route table public"
    }
}

resource "aws_route_table_association" "public" {
    subnet_id = "${aws_subnet.public.id}"
    route_table_id = "${aws_route_table.public.id}"
}


resource "aws_route" "igw" {
    gateway_id = "${aws_internet_gateway.gw.id}"
    route_table_id = "${aws_route_table.public.id}"
    destination_cidr_block = "0.0.0.0/0"

    depends_on = ["aws_route_table.public"]
}

resource "aws_route" "ngw" {
    nat_gateway_id = "${aws_nat_gateway.gw.id}"
    route_table_id = "${aws_vpc.vpc.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
}


#Creating Security Groups

resource "aws_security_group" "db" {
  name        = "db Security Group"
  description = "Allow SSH and mysql inbound traffic"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "DB"
  }
}

resource "aws_security_group" "ei" {
  name        = "EI Security Group"
  description = "Allow SSH inbound traffic"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 4100
    to_port     = 4100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 8280
    to_port     = 8280
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 8243
    to_port     = 8243
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "EI"
  }
}


resource "aws_security_group" "nginx" {
  name        = "nginx Security Group"
  description = "Allow SSH inbound traffic"
  vpc_id = "${aws_vpc.vpc.id}"
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
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "NGINX"
  }
}


data "template_file" "ansible" {
  template = "${file("ansible.tpl")}"
}



resource "aws_instance" "ei" {
  count 	= 2
  subnet_id 	= "${aws_subnet.public.id}"
  ami           = "${lookup(var.amis, var.region)}"
  instance_type = "${var.instance_type}"
  user_data     = "${data.template_file.ansible.rendered}"
  security_groups = [
  	"${aws_security_group.ei.id}"
  ]
  tags {
    Name = "mmb.demo.ei"
  }
 key_name = "useast"
}


resource "aws_instance" "nginx" {
  count 	= 1
  subnet_id 	= "${aws_subnet.public.id}"
  ami           = "${lookup(var.amis, var.region)}"
  instance_type = "${var.instance_type}"
  user_data     = "${data.template_file.ansible.rendered}"
  security_groups = [
  	"${aws_security_group.nginx.id}"
  ]
  tags {
    Name = "mmb.demo.nginx"
  }
 key_name = "useast"
}

resource "aws_instance" "db" {
  count 	= 1
  subnet_id 	= "${aws_subnet.public.id}"
  ami           = "${lookup(var.amis, var.region)}"
  instance_type = "${var.instance_type}"
  user_data     = "${data.template_file.ansible.rendered}"
  security_groups = [
  	"${aws_security_group.db.id}"
  ]
  tags {
    Name = "mmb.demo.db"
  }
 key_name = "useast"
}



output "SSH String for nginx  Server" {
  value = "ssh ec2-user@${aws_instance.nginx.public_ip}"
}

output "SSH String for db Server" {
  value = "ssh ec2-user@${aws_instance.db.public_ip}"
}
output "VPC Name" {
  value = "${aws_vpc.vpc.id}"
}

