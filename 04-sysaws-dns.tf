# Create the Zone
resource "aws_route53_zone" "okd" {
  name = "${var.domain}"
  }

# Get main zone info
data "aws_route53_zone" "main" {
  name = "${var.maindomain}"
}

# Create NS record in main zone
resource "aws_route53_record" "okd-ns" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${var.domain}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.okd.name_servers.0}",
    "${aws_route53_zone.okd.name_servers.1}",
    "${aws_route53_zone.okd.name_servers.2}",
    "${aws_route53_zone.okd.name_servers.3}",
  ]
}

resource "aws_route53_record" "wildcard" {
  zone_id = "${aws_route53_zone.okd.zone_id}"
  name    = "*.${var.domain}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.app1.public_ip}"]
}


resource "aws_route53_record" "collector" {
    zone_id = "${aws_route53_zone.okd.zone_id}"
    name    = "collector.${var.domain}"
    type    = "CNAME"
    ttl     = "300"

    weighted_routing_policy {
    weight = 50
  }
    set_identifier = "collector"
    records        = ["${aws_elb.okd.dns_name}"]
}

resource "aws_route53_record" "sysdig" {
    zone_id = "${aws_route53_zone.okd.zone_id}"
    name    = "sysdig.${var.domain}"
    type    = "CNAME"
    ttl     = "300"

    weighted_routing_policy {
    weight = 50
  }
    set_identifier = "sysdig"
    records        = ["${aws_elb.okd.dns_name}"]
}