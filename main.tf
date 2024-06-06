provider "aws" {
  region = "us-west-2"  # Change to your preferred region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["59.184.156.139/32"]  # Replace YOUR_IP with your IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]  # Allow traffic from both subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0eb9d67c52f5c80e5"  # Replace with your desired AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_a.id
  security_groups = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
sudo apt update -y
sudo apt install -y apache2 mariadb-server

# Install PHP and necessary PHP modules
sudo apt install -y php libapache2-mod-php php-mysql php-mbstring php-xml

# Start and enable Apache
sudo systemctl start apache2
sudo systemctl enable apache2

# Adjust permissions
sudo usermod -a -G www-data ubuntu
sudo chown -R ubuntu:www-data /var/www/html
sudo chmod -R 2775 /var/www/html
find /var/www/html -type f -exec sudo chmod 0664 {} \;

# Install phpMyAdmin
sudo apt install -y phpmyadmin

# Restart Apache and PHP
sudo systemctl restart apache2
sudo systemctl restart php7.2-fpm

# Cleanup
cd /var/www/html
sudo wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
sudo mkdir phpMyAdmin
sudo tar -xvzf phpMyAdmin-latest-all-languages.tar.gz -C phpMyAdmin --strip-components 1
sudo rm phpMyAdmin-latest-all-languages.tar.gz

  EOF

  tags = {
    Name = "WebInstance"
  }
}

resource "aws_instance" "db" {
  ami           = "ami-0eb9d67c52f5c80e5"  # Replace with your desired AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_b.id  # Place in different AZ
  security_groups = [aws_security_group.db_sg.id]

  user_data = <<-EOF
 #!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2

# Install Apache and PHP
sudo yum install -y httpd php php-mysql php-mbstring php-xml

# Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# Adjust permissions
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www/html
sudo chmod 2775 /var/www/html && find /var/www/html -type d -exec sudo chmod 2775 {} \;
find /var/www/html -type f -exec sudo chmod 0664 {} \;

# Download and deploy your application (replace with your actual deployment steps)
cd /var/www/html
sudo wget -O app.tar.gz https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
sudo tar -xzf app.tar.gz
sudo rm app.tar.gz

# Restart Apache
sudo systemctl restart httpd


  EOF

  tags = {
    Name = "DBInstance"
  }
}

resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "web_tg_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_instance" "bastion" {
  ami           = "ami-0eb9d67c52f5c80e5"  # Replace with your desired AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_a.id
  security_groups = [aws_security_group.web_sg.id]

  tags = {
    Name = "BastionHost"
  }
}
