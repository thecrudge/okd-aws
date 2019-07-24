
# --- Amazon Variables
variable "aws_access_key" {
  description = "Aws Access Key"
  default = "<AWS ACCESS KEY>"
}

variable "aws_secret_key" {
  description = "Aws Secret Key"
  default = "<AWS SECRET KEY>"
}

variable "maindomain" {
  default = "example.com"
}

variable "domain" {
  default = "<INSERT SUBDOMAIN HERE>.example.com"
}

variable "ami-id" {
  default = "ami-9887c6e7"
}

# This variable is the user i.e. ec2-user, in this case the ami uses 'centos'
variable "ami-user" {
  default = "centos"
}

variable "bastion-size" {
  default = "c5.2xlarge"
}

variable "master-size" {
  default = "c5.2xlarge"
}

variable "node-size" {
  default = "c5.2xlarge"
}

# --- System Variables

variable "id_rsa" {
  description = "location of .ssh/id_rsa private key"
  default = "<PATH TO PRIVATE KEY>/.ssh/id_rsa"
}

variable "id_rsapub" {
  description = "location of .ssh/id_rsa.pub public key"
  default = "<PATH TO PUBLIC KEY>/.ssh/id_rsa.pub"
}

variable "okd-key" {
  default = "<CONTENTS OF ID_RSA.PUB i.e cat id_rsa.pub> "
}

variable "release" {
  default = "3.11"
}

variable "clusterid" {
  default = "<NAME YOUR CLUSTER HERE>"
}
