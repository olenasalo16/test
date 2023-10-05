terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.19.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

#############################
#Create VPC

resource "aws_vpc" "wordpress-vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "wordpress-vpc"
  }
}

###########################
#Create IGW

resource "aws_internet_gateway" "wordpress_igw" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "wordpress_igw"
  }
}

#############################
#Create Route Table

resource "aws_route_table" "wordpress-rt" {
  vpc_id = aws_vpc.wordpress-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress_igw.id
  }

  tags = {
    Name = "wordpress-rt"
  }
}

##############################
#Create public subnets

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = var.public_subnet_a_cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = "public_subnet_a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = var.public_subnet_b_cidr_block
  availability_zone = "us-east-1b"

  tags = {
    Name = "public_subnet_b"
  }
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = var.public_subnet_c_cidr_block
  availability_zone = "us-east-1c"

  tags = {
    Name = "public_subnet_c"
  }
}

#############################
#Create private subnets

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = var.private_subnet_a_cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_subnet_a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = var.private_subnet_b_cidr_block
  availability_zone = "us-east-1b"

  tags = {
    Name = "private_subnet_b"
  }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = var.private_subnet_c_cidr_block
  availability_zone = "us-east-1c"

  tags = {
    Name = "private_subnet_c"
  }
}

######################################
#Subnet association

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.wordpress-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.wordpress-rt.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.wordpress-rt.id
}

###################################

# Create security group
resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress-sg"
  description = "Security group for WordPress"
  vpc_id      = aws_vpc.wordpress-vpc.id

  # Ingress rules for HTTP, HTTPS, and SSH
  ingress {
    from_port   = var.ingress_ports[0]
    to_port     = var.ingress_ports[0]
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.ingress_ports[1]
    to_port     = var.ingress_ports[1]
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.ingress_ports[2]
    to_port     = var.ingress_ports[2]
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
}


##############################
# instance with key

resource "aws_instance" "wordpress-ec2" {
  ami                    = var.ami_id
  instance_type          = var.ec2_type
  subnet_id = aws_subnet.public_subnet_a.id
  associate_public_ip_address = true
  key_name = var.ssh_key_name

  user_data = <<-EOF
              #!/bin/bash
yum update -y
yum install httpd php php-mysql -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
cd /var/www/html
wget https://wordpress.org/wordpress-5.1.1.tar.gz
tar -xzf wordpress-5.1.1.tar.gz
cp -r wordpress/* /var/www/html/
rm -rf wordpress
rm -rf wordpress-5.1.1.tar.gz
chmod -R 755 *
chown -R apache:apache *
chkconfig httpd on
service httpd start
              EOF

  tags = {
    Name = "wordpress-ec2"
  }
}

 
resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.wordpress_sg.id
  network_interface_id = aws_instance.wordpress-ec2.primary_network_interface_id
}
#####################################
# Create security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.wordpress-vpc.id

  # Ingress rule to allow traffic only from the wordpress-sg security group
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.wordpress_sg.id]
  }

  tags = {
    Name = "rds-sg"
  }
}
##################################
# Create db instance


resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "mysql-db-subnet-group"
  description = "Subnet group for MySQL DB instance"
  subnet_ids  = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id, aws_subnet.private_subnet_c.id]
}


resource "aws_db_instance" "wordpress_mysql" {
  allocated_storage    = 20
  storage_type         = "gp2"
  db_name              = "wordpress"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "adminadmin"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id

}


