output "ec2_pvt_ips" {
  value = aws_spot_instance_request.ec2_spot.*.private_ip
}