locals {
  db_user           = var.db_master_username
  db_password       = var.db_master_password
  db_host           = aws_rds_cluster.db.endpoint
  db_port           = aws_rds_cluster.db.port
  db_name           = aws_rds_cluster.db.database_name
  db_url            = "mysql:host=${aws_rds_cluster.db.endpoint};dbname=${aws_rds_cluster.db.database_name};port=${aws_rds_cluster.db.port}"
  security_group_id = null == var.db_security_group_id ? aws_security_group.default[0].id : var.db_security_group_id
}