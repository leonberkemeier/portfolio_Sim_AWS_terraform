# Security group for the Database to control inbound/outbound traffic
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Allow inbound Postgres traffic from within the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    # Allow traffic from anywhere inside the VPC (Layer 1, 2, and 3)
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A DB subnet group tells RDS which subnets it is allowed to use.
# Note: RDS requires at least 2 subnets in different availability zones. 
# For simplicity in this base configuration we assume standard usage, but you'll need secondary subnets for actual HA.
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.public.id] # Usually two private subnets are used here
}

# The actual Amazon RDS Database instance (Replacing SQLite)
resource "aws_db_instance" "postgres" {
  identifier           = "${var.project_name}-db"
  engine               = "postgres"
  engine_version       = "15.4"               # Using a stable, modern Postgres version
  instance_class       = "db.t3.micro"        # Cheap instance for dev, scale up for prod
  allocated_storage    = 20                   # 20 GB of SSD storage
  
  db_name              = "financial"          # The default database name
  username             = "postgres_admin"
  password             = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  skip_final_snapshot    = true               # Skips backups on destruction (good for dev, bad for prod)
  publicly_accessible    = false              # Kept private for security
  
  # Ensure automated backups are enabled. Required to create Read Replicas!
  backup_retention_period = 7
}

# ----------------------------------------------------------------------
# NEW: RDS Read Replica for Heavy Analytics
# ----------------------------------------------------------------------
resource "aws_db_instance" "postgres_replica" {
  identifier             = "${var.project_name}-db-replica"
  replicate_source_db    = aws_db_instance.postgres.identifier
  instance_class         = "db.t3.micro"        # Should be scaled to match compute needs in prod
  
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  # Replicas do not specify database name, password, or subnet group 
  # as they inherit these from the primary instance.
}
