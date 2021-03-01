resource "aws_route53_zone" "my-private_zone" {
  name = "keepcoding-practica.com"
  vpc {
    vpc_id = aws_vpc.final-vpc.id
  }
}
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.my-private_zone.zone_id
  name    = "keepcoding-practica.com"
  type    = "A"
  alias {
    name                   = aws_alb.web-alb.dns_name
    zone_id                = aws_alb.web-alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_security_group" "Bastion-sg" {
  name   = "DataBase-sg"
  vpc_id = aws_vpc.final-vpc.id
  ingress {
    description = "IANA "
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "F-Bastion-sg"
  }
}

resource "aws_instance" "bastion" {
  ami                         = "ami-0c95efaa8fa6e2424"
  instance_type               = "t2.large"
  subnet_id                   = aws_subnet.public-subnet1.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [
    aws_security_group.Bastion-sg.id
  ]
  disable_api_termination = false
  monitoring              = false
  tags = {
    Name = "Bastion-hosted-zone"
  }
  depends_on = [
    aws_subnet.public-subnet1
  ]
}
