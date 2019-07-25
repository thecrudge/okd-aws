resource "aws_instance" "master1" {
   ami           = "${var.ami-id}"
   instance_type = "${var.master-size}"
   key_name = "${aws_key_pair.okd.key_name}"
   subnet_id = "${aws_subnet.okd-1a-pub.id}"
   vpc_security_group_ids = ["${aws_security_group.master.id}","${aws_security_group.node.id}"]
   depends_on = ["aws_ebs_volume.master1"]

  tags = {
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
    host = "${aws_instance.master1.public_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/origin/master",
      "sudo touch /etc/origin/master/htpasswd",
      "sudo yum install -y NetworkManager kernel-headers httpd-tools wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct",
      "sudo yum update -y",
      "sudo systemctl enable NetworkManager",
      "sudo systemctl start NetworkManager",
      "sudo yum -y install docker",
      "git clone https://github.com/draios/sysdigcloud-kubernetes.git"
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

resource "aws_ebs_volume" "master1" {
    availability_zone = "us-east-1a"
    size              = 60


    tags = {
      KubernetesCluster = "${var.clusterid}"
  }
}

resource "aws_volume_attachment" "master1" {
  device_name = "/dev/sdb"
  volume_id   = "${aws_ebs_volume.master1.id}"
  instance_id = "${aws_instance.master1.id}"
}

resource "aws_route53_record" "master1" {
  zone_id = "${aws_route53_zone.okd.zone_id}"
  name    = "master1.${var.domain}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.master1.public_ip}"]
}

