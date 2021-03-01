
# DB instance
resource "aws_db_subnet_group" "DB-subnet-gr" {
  name       = "main"
  subnet_ids = [aws_subnet.private-subnet1.id, aws_subnet.private-subnet2.id]

  tags = {
    Name = "F-DB-subnet-group"
  }
}

resource "aws_db_instance" "DB-instance" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t2.micro"
  name                   = "mydb"
  username               = "admin"
  password               = "admin123"
  db_subnet_group_name   = aws_db_subnet_group.DB-subnet-gr.id
  vpc_security_group_ids = [aws_security_group.DataBase-sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "F-DB-instance"
  }
}

#ASG
resource "aws_launch_configuration" "web-lc" {
  depends_on           = [aws_security_group.ec2-webServers-sg]
  name                 = "web-lc"
  image_id             = "ami-0fc970315c2d38f01"
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.ec2-webServers-sg.id]
  key_name             = "practica_final_kp"
  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.id
  user_data            = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start              
              sudo docker run -d --name rtb -p 8080:8080 --restart always vermicida/rtb
  EOF
}

resource "aws_autoscaling_group" "ec2-web-asg" {
  name                 = "ec2-web-asg"
  max_size             = 2
  min_size             = 2
  force_delete         = true
  launch_configuration = aws_launch_configuration.web-lc.name
  vpc_zone_identifier  = [aws_subnet.private-subnet1.id, aws_subnet.private-subnet2.id]
  tag {
    key                 = "Name"
    value               = "ec2-web"
    propagate_at_launch = "true"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.ec2-web-asg.id
  alb_target_group_arn   = aws_alb_target_group.tg-alb.arn
}

#Key-pair
resource "aws_key_pair" "my_key_pair" {
  key_name   = "practica_final_kp"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAqB9zbbm1uAS8eN6oNowRc8mPlk2orVIE9WksUvdrbWPlMlZXKXxNvsg32M6WSypmU/CmocOvibwnbTN3LWIRFfmT/7e1xTjfOg5n/sMUwVP1sH7EEjNcQnZHA6TZkJF6k659nzxOa+MYvN/bwfvMlMrjypFGfckYMRFJ7w4k4jEJ0x50w7xBm25892In22wkXSp8V1bDd3RnXxAVQffBWwYVzhzZIlCWkJWVXlKA22X4tbQcGufPMsYf6IclqWe9cMGVyhsZwaPXX/y6eZz2iMDiyeT9fQ1mQbrAeMQpwqc9WVJ1YzlJnr9ghyqX5DAGzRQCYdZbiQazsnN/SF3D9w== rsa-key-20210128"
}

#Secret manager
resource "aws_secretsmanager_secret" "rtb-db-secret" {
  name                    = "rtb-db-secret"
  recovery_window_in_days = 0
  description             = "Webapp database connection secret"
  tags = {
    Name = "DB-Secrets"
  }
}

resource "aws_secretsmanager_secret_version" "db_conn_secret_value" {
  secret_id = aws_secretsmanager_secret.rtb-db-secret.id
  secret_string = jsonencode({
    username = "admin",
    password = "admin123",
    host     = aws_db_instance.DB-instance.address,
    db       = "mydb"
  })
}

