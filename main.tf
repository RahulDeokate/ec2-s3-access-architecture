resource "aws_vpc" "webapp-vpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub-1" {
  vpc_id = aws_vpc.webapp-vpc.id
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  cidr_block = var.cidr-sub1
}

resource "aws_subnet" "sub-2" {
  vpc_id = aws_vpc.webapp-vpc.id
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
  cidr_block = var.cidr-sub2
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.webapp-vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.webapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.sub-1.id
    route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.sub-2.id
    route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "web-sg" {
  name = "web-sg"
  vpc_id = aws_vpc.webapp-vpc.id

  ingress {
    description = "allow http traffic from everywhere"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow ssh traffic from everywhere"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "rahul-deokate-webapp-demo-bucket"
}

resource "aws_instance" "web-server-1" {
  ami = var.ami
  instance_type = var.instance-type
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  subnet_id = aws_subnet.sub-1.id
  user_data_base64 = base64encode(file("userdata.ssh"))
}

resource "aws_instance" "web-server-2" {
  ami = var.ami
  instance_type = var.instance-type
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  subnet_id = aws_subnet.sub-2.id
  user_data_base64 = base64encode(file("userdata1.ssh"))

}

resource "aws_lb" "loadbalancer" {
  name = "loadbalancer"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.web-sg.id]
  subnets = [aws_subnet.sub-1.id, aws_subnet.sub-2.id]
}

resource "aws_lb_target_group" "target-gp" {
  name = "my-target-gp"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.webapp-vpc.id

  health_check {
  path                = "/"
  port                = "traffic-port"
  protocol            = "HTTP"
  healthy_threshold   = 2
  unhealthy_threshold = 2
  interval            = 30
  timeout             = 5
  matcher             = "200"
}

}

resource "aws_lb_target_group_attachment" "target-attach1" {
    target_group_arn = aws_lb_target_group.target-gp.arn
    target_id = aws_instance.web-server-1.id
    port = 80
    depends_on = [aws_lb.loadbalancer]
}

resource "aws_lb_target_group_attachment" "target-attach2" {
    target_group_arn = aws_lb_target_group.target-gp.arn
    target_id = aws_instance.web-server-2.id
    port = 80
    depends_on = [aws_lb.loadbalancer]
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target-gp.arn
    type = "forward"
  }
}