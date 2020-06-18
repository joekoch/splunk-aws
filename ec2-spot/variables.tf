variable "subnetAid" {}
variable "subnetACIDR" {}
variable "subnetBCIDR" {}
variable "subnetCCIDR" {}
variable "subnetDCIDR" {}
variable "vpc_id" {}

variable "key_name" {}
variable "cloudwatch_retention" {
  default = 30
}
variable "cloudwatch_loggroup_name" {}
variable "sub_volume_size" {}
variable "root_volume_size" {}
variable "project_name" {}

variable "environment" {}
variable "region" {}
variable "app" {}
variable "init_script" {}
variable "app_function" {}
variable "ami" {}
variable "ec2_instance_type" {}
variable "fromport" {}
variable "toport" {}
variable "spot_price" {}
variable "ec2_depends_on" {
  default = null
}

variable "ec2_spot_count" {}
variable "spot_type" {}
variable "ip_addtl_allow" {}