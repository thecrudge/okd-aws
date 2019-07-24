resource "aws_instance" "app4" {
   ami           = "${var.ami-id}"
   instance_type = "${var.node-size}"
   key_name = "${aws_key_pair.okd.key_name}"
   subnet_id = "${aws_subnet.okd-1a-pub.id}"
   vpc_security_group_ids = ["${aws_security_group.node.id}"]
   depends_on = ["aws_ebs_volume.app4"]

   tags {
    KubernetesCluster = "${var.clusterid}"
  }

  root_block_device {
    volume_size = 200
    delete_on_termination = true
  }
   
  connection {
    type     = "ssh"
    user     = "${var.ami-user}"
    private_key = "${file("${var.id_rsa}")}"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y NetworkManager kernel-headers wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct",
      "sudo yum update -y",
      "sudo systemctl enable NetworkManager",
      "sudo systemctl start NetworkManager",
      "sudo yum -y install docker"
    ]
  }

  provisioner "file" {
     source = "docker-storage-setup"
     destination = "/tmp/docker-storage-setup"
  }

  provisioner "remote-exec" {
     inline = [
       "sudo cp /tmp/docker-storage-setup /etc/sysconfig/docker-storage-setup"
     ]
  }
}

resource "aws_ebs_volume" "app4" {
    availability_zone = "us-east-1a"
    size              = 60
    tags = {
      KubernetesCluster = "${var.clusterid}"
  }
}

resource "aws_volume_attachment" "app4" {
  device_name = "/dev/sdb"
  volume_id   = "${aws_ebs_volume.app4.id}"
  instance_id = "${aws_instance.app4.id}"
}

resource "aws_route53_record" "app4" {
  zone_id = "${aws_route53_zone.okd.zone_id}"
  name    = "app4.${var.domain}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.app4.public_ip}"]
}

