# Enhanced EC2 Instance with better user_dataresource "aws_instance" "my_instance" {
# resource "aws_instance" "my_instance" {
#   ami           = "ami-058a8a5ab36292159" # Verified Amazon Linux 2 in us-east-2
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.public_subnet.id

#   vpc_security_group_ids = [aws_security_group.instance_sg.id] # Explicit SG attachment

#First step in creating an ASG is a launch configuration or template
# Create new key pair
# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "terraform-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Launch Template
resource "aws_launch_template" "example" {
  name_prefix   = "example-template-"
  image_id      = "ami-058a8a5ab36292159"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log) 2>&1
              yum install -y busybox
              mkdir -p /var/www/html
              echo "OK" > /var/www/html/health
              nohup busybox httpd -f -p ${var.server_port} -h /var/www/html &
              EOF
              )

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "example" {
  name                = "terraform-asg-example"
  min_size            = 2
  max_size            = 10
  vpc_zone_identifier = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]
  target_group_arns   = [aws_lb_target_group.asg.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "terraform-example-alb-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.alb.id]
}

# Target Group
resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# Instance Security Group
resource "aws_security_group" "instance" {
  name        = "terraform-example-instance"
  description = "Allow HTTP and SSH access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP Access"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Outputs
output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "DNS name of the ALB"
}

output "user_data_log" {
  value = "/var/log/user-data.log"
}