resource "aws_instance" "my_instance" {
  ami                    = "ami-058a8a5ab36292159"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Oi, Brasil!" > /var/www/html/index.html
              nohup busybox httpd -f -p 8080 &
              EOF


  tags = {
    Name = "My EC2 Instance"
  }
}


