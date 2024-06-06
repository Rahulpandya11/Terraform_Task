output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id_a" {
  value = aws_subnet.private_a.id
}

output "subnet_id_b" {
  value = aws_subnet.private_b.id
}

output "web_instance_id" {
  value = aws_instance.web.id
}

output "db_instance_id" {
  value = aws_instance.db.id
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}
