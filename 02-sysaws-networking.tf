# Create VPC
resource "aws_vpc" "okd" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Create IGW
resource "aws_internet_gateway" "okd" {
  vpc_id = "${aws_vpc.okd.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "inet-pub" {
  route_table_id         = "${aws_vpc.okd.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.okd.id}"
}

resource "aws_subnet" "okd-1a-pub" {
  vpc_id     = "${aws_vpc.okd.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags {
    KubernetesCluster = "${var.clusterid}"
  }
}

# Associate the subnets with routing tables
resource "aws_route_table_association" "okd-1a-pub" {
  subnet_id      = "${aws_subnet.okd-1a-pub.id}"
  route_table_id = "${aws_vpc.okd.main_route_table_id}" 
}

# Create Load Balancer

resource "aws_elb" "okd" {
  name               = "${var.clusterid}-elb"

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
     instance_port     = 443
     instance_protocol = "tcp"
     lb_port           = 443
     lb_protocol       = "tcp"
   }

  listener {
     instance_port     = 6443
     instance_protocol = "tcp"
     lb_port           = 6443
     lb_protocol       = "tcp"
   }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:80"
    interval            = 30
  }

  instances                   = ["${aws_instance.app1.id}","${aws_instance.app2.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  security_groups = ["${aws_security_group.infra.id}"]
  subnets = ["${aws_subnet.okd-1a-pub.id}"]
  }