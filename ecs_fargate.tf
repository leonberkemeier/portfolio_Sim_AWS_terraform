# Amazon Elastic Container Registry (ECR)
# Holds the Docker images for our Layer 1 (ETL) and Layer 3 (Simulator API)
resource "aws_ecr_repository" "etl_repo" {
  name                 = "${var.project_name}-etl"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "simulator_repo" {
  name                 = "${var.project_name}-simulator-api"
  image_tag_mutability = "MUTABLE"
}

# Amazon Elastic Container Service (ECS) Cluster
# The logical grouping of our Fargate tasks
resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.project_name}-cluster"
}

# Note: In a complete deployment, you would add:
# 1. aws_ecs_task_definition to define the CPU/RAM and point to your docker image in ECR
# 2. aws_ecs_service to keep Layer 3 API running 24/7
# 3. aws_cloudwatch_event_rule to schedule Layer 1 ETL to run as standalone tasks
# 4. An Application Load Balancer (ALB) to route HTTP traffic into the Layer 3 API
