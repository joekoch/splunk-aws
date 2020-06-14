locals {
  base_tags = {
    project = var.project_name
    env     = var.environment
    app     = var.app
  }
}

#create a cloudwatch log group for this project
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.cloudwatch_loggroup_name}-${var.project_name}-${var.app}-${var.app_function}"
  retention_in_days = var.cloudwatch_retention
  tags              = merge(local.base_tags, map("Name", "cloudwatch-log-group"))
}


resource "aws_iam_role" "ec2_role" {
  name                  = "ec2_role-${var.project_name}-${var.app_function}-${var.app}"
  path                  = "/"
  force_detach_policies = true
  # who can assume this role
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
  tags               = merge(local.base_tags, map("Name", "ec2-role"))
}

resource "aws_iam_policy" "ssm_s3_endpoint" {
  policy = <<EOF
{
  "Version": "2012-10-17",
"Statement":[{
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": [
                "arn:aws:s3:::aws-ssm-${var.region}/*",
                "arn:aws:s3:::aws-windows-downloads-${var.region}/*",
                "arn:aws:s3:::amazon-ssm-${var.region}/*",
                "arn:aws:s3:::amazon-ssm-packages-${var.region}/*",
                "arn:aws:s3:::${var.region}-birdwatcher-prod/*",
                "arn:aws:s3:::patch-baseline-snapshot-${var.region}/*"
            ]
        }]
}
EOF
}
#attach the policy to the iam role
resource "aws_iam_policy_attachment" "ec2_attach_cloudwatch" {
  name       = "ec2_attach_cloudwatch"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  roles = [
  aws_iam_role.ec2_role.id]
}

#attach the policy to the iam role
resource "aws_iam_policy_attachment" "ec2_attach_ec2" {
  name       = "ec2_attach_ec2"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  roles = [
  aws_iam_role.ec2_role.id]
}

#attach the policy to the iam role
resource "aws_iam_policy_attachment" "ec2_attach_asg" {
  name       = "ec2_attach_asg"
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingReadOnlyAccess"
  roles = [
  aws_iam_role.ec2_role.id]
}

#attach the policy to the iam role
resource "aws_iam_policy_attachment" "ec2_attach_ssm" {
  name       = "ec2_attach_ssm"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  roles = [
  aws_iam_role.ec2_role.id]
}

#attach the policy to the iam role
resource "aws_iam_policy_attachment" "ec2_attach_ssm_s3" {
  name       = "ec2_attach_ssm_s3"
  policy_arn = aws_iam_policy.ssm_s3_endpoint.arn
  roles = [
  aws_iam_role.ec2_role.id]
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "iam_instance_profile-${var.app}-${var.app_function}"
  role = aws_iam_role.ec2_role.id
}

#common cloud init script for cloudwatch
#customize log group name as per project and start agent
data template_file "cloud_watch" {
  template = file("${path.module}/cloudwatch_config.sh")
  vars = {
    cw_log_group = var.project_name
  }
}

#init logic for ixr master
data "template_file" "init" {
  template = var.init_script
}

data "template_cloudinit_config" "cloud_init" {
  gzip          = false
  base64_encode = false

  # cloud-config configuration file for cloudwatch.
  part {
    filename     = "cloud_watch.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.cloud_watch.rendered
  }
  part {
    filename     = "init.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.init.rendered
  }
}


resource "aws_security_group" "sg_base" {
  name        = "SG-${var.project_name}-${var.app}-${var.app_function}"
  description = "Used by members for splunk shc"
  vpc_id      = var.vpc_id

  #unknown
  egress {
    from_port = var.fromport
    to_port   = var.toport
    protocol  = "tcp"
    cidr_blocks = [
    var.subnetACIDR]
  }

  ingress {
    from_port = var.fromport
    to_port   = var.toport
    protocol  = "tcp"
    cidr_blocks = [
    var.subnetACIDR]
  }




  #unknown
  ingress {
    from_port = var.fromport
    to_port   = var.toport
    protocol  = "tcp"
    cidr_blocks = [
    var.subnetACIDR]
  }

  #aws cli
  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  #ubuntu package update
  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }


  #SSH
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
    var.subnetCCIDR]
  }

  tags = merge(local.base_tags, map("Name", "SG-base"))

}


resource "aws_spot_instance_request" "ec2_spot" {
  count = var.ec2_spot_count
  ami   = var.ami
  depends_on = [
  var.ec2_depends_on]
  instance_type        = var.ec2_instance_type
  wait_for_fulfillment = true
  spot_type            = var.spot_type
  spot_price           = var.spot_price
  key_name             = var.key_name
  security_groups = [
  aws_security_group.sg_base.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.id
  user_data            = data.template_cloudinit_config.cloud_init.rendered
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "standard"
    volume_size = var.sub_volume_size
  }
  root_block_device {
    volume_type = "standard"
    volume_size = var.root_volume_size
  }
  subnet_id = var.subnetAid
  tags      = merge(local.base_tags, map("Name", "${var.project_name}--${var.app}-${var.app_function}"))

}