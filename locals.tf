locals {
  is_serverless_v2  = var.db_serverless_version == "v2"
  is_postgres       = (var.db_engine == "aurora-postgresql") || (var.db_engine == "postgres")
  db_default_port   = local.is_postgres ? 5432 : 3306
  db_dsn_prefix     = local.is_postgres ? "postgres" : "mysql"
  db_user           = var.db_master_username
  db_password       = var.db_master_password
  db_host           = aws_rds_cluster.db.endpoint
  db_host_ro        = aws_rds_cluster.db.reader_endpoint
  db_port           = aws_rds_cluster.db.port
  db_name           = aws_rds_cluster.db.database_name
  db_url            = "${local.db_dsn_prefix}:host=${aws_rds_cluster.db.endpoint};dbname=${aws_rds_cluster.db.database_name};port=${aws_rds_cluster.db.port}"
  db_url_ro         = "${local.db_dsn_prefix}:host=${aws_rds_cluster.db.reader_endpoint};dbname=${aws_rds_cluster.db.database_name};port=${aws_rds_cluster.db.port}"
  security_group_id = null == var.db_security_group_id ? aws_security_group.default[0].id : var.db_security_group_id
}