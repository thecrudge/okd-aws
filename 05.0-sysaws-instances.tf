resource "aws_key_pair" "okd" {
  key_name   = "${var.clusterid}"
  public_key = "${var.okd-key}"
}


# Start deploying instances

resource "aws_instance" "bastion" {
   ami           = "${var.ami-id}"
   instance_type = "${var.bastion-size}"
   key_name = "${aws_key_pair.okd.key_name}"
   subnet_id = "${aws_subnet.okd-1a-pub.id}"
   vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
   depends_on = ["aws_instance.app1", "aws_instance.app2","aws_instance.master1"]

   tags {
    KubernetesCluster = "${var.clusterid}"
  }

  connection {
    type     = "ssh"
    user     = "${var.ami-user}"
    private_key = "${file("${var.id_rsa}")}"
    agent = false
  }

  provisioner "file" {
    source      = "${var.id_rsa}"
    destination = "/home/${var.ami-user}/.ssh/id_rsa"
  }

  provisioner "file" {
    source      = "sshconfig"
    destination = "/home/${var.ami-user}/.ssh/config"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 0400 /home/${var.ami-user}/.ssh/config",
      "sudo chmod 0400 /home/${var.ami-user}/.ssh/id_rsa",
      "sudo yum install -y wget NetworkManager git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct",
      "sudo yum update -y",
      "sudo systemctl enable NetworkManager",
      "sudo systemctl start NetworkManager"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install epel-release", 
      "sudo yum -y install pyOpenSSL",
      "sudo yum -y install https://releases.ansible.com/ansible/rpm/release/epel-7-x86_64/ansible-2.6.16-1.el7.ans.noarch.rpm",
      "sleep 10",
      "git clone https://github.com/openshift/openshift-ansible",
      "cd openshift-ansible",
      "git checkout release-${var.release}"
    ]
  }

  provisioner "file" {
    source      = "hosts.inventory"
    destination = "/home/${var.ami-user}/hosts.inventory"
  }
}

resource "aws_route53_record" "bastion" {
  zone_id = "${aws_route53_zone.okd.zone_id}"
  name    = "bastion.${var.domain}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.bastion.public_ip}"]
}