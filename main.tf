resource "aws_rds_cluster" "db" {
  cluster_identifier           = "${var.env}-${var.name}"
  engine                       = var.db_engine
  engine_version               = var.db_engine_version
  engine_mode                  = var.db_engine_mode
  availability_zones           = var.db_availability_zones
  database_name                = var.db_name
  final_snapshot_identifier    = "${replace(var.db_name, "_", "-")}-final"
  master_username              = var.db_master_username
  master_password              = var.db_master_password
  backup_retention_period      = var.db_backup_retention_period
  preferred_backup_window      = var.db_preferred_backup_window
  skip_final_snapshot          = false
  vpc_security_group_ids       = [local.security_group_id]
  db_subnet_group_name         = aws_db_subnet_group.default.name
  enable_http_endpoint         = local.is_serverless_v2 ? false : true
  preferred_maintenance_window = var.db_preferred_maintenance_window

  apply_immediately         = var.db_apply_immediately

  dynamic "scaling_configuration" {
    for_each = local.is_serverless_v2 ? {} : {v = true}
    content {
      auto_pause               = var.db_auto_pause
      max_capacity             = var.db_max_capacity
      min_capacity             = var.db_min_capacity
      seconds_until_auto_pause = var.db_auto_pause_delay
    }
  }
  dynamic "serverlessv2_scaling_configuration" {
    for_each = local.is_serverless_v2 ? {v = true} : {}
    content {
      max_capacity             = var.db_max_capacity
      min_capacity             = var.db_min_capacity
    }
  }
  lifecycle {
    ignore_changes = [engine_version]
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "default" {
  name        = "${var.env}_db_subnets"
  description = "Group of DB subnets - ${var.env}"
  subnet_ids  = [for k,v in var.db_subnets: v.id]
}

resource "aws_security_group" "default" {
  count       = null == var.db_security_group_id ? 1 : 0
  vpc_id      = var.db_vpc_id
  name        = format("%s-%s-sg", var.env, "aurora")
  description = format("Security Group for %s - %s", "aurora", var.env)
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "aurora-incoming" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = local.db_default_port
  to_port           = local.db_default_port
  cidr_blocks       = [for k,v in var.db_subnets: v.cidr_block]
  security_group_id = local.security_group_id
}
resource "aws_security_group_rule" "aurora-outgoing" {
  count             = null == var.db_security_group_id ? 1 : 0
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = local.security_group_id
}

resource "aws_rds_cluster_instance" "instance" {
  count                        = (var.db_engine_mode == "serverless") ? 0 : 1
  identifier                   = "${var.env}-${var.name}-${count.index}"
  cluster_identifier           = aws_rds_cluster.db.id
  instance_class               = var.db_instance_class
  engine                       = aws_rds_cluster.db.engine
  engine_version               = aws_rds_cluster.db.engine_version
  apply_immediately            = var.db_apply_immediately
  db_subnet_group_name         = aws_rds_cluster.db.db_subnet_group_name
  preferred_backup_window      = var.db_preferred_backup_window
  preferred_maintenance_window = var.db_preferred_maintenance_window
}