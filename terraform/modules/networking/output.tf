output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "public_route_table_id" {
  value = aws_route_table.main.id
}

output "public_route_table_association_id" {
  value = aws_route_table_association.public.id
}