# Dead Letter Queue (DLQ) for failed portfolio evaluations
resource "aws_sqs_queue" "portfolio_dlq" {
  name = "${var.project_name}-portfolio-eval-dlq"
}

# The main SQS Queue for scheduling Portfolio Evaluations (Layer 2 GPU Worker pulls from here)
resource "aws_sqs_queue" "portfolio_queue" {
  name                       = "${var.project_name}-portfolio-eval-queue"
  delay_seconds              = 0
  max_message_size           = 262144           # 256 KB
  message_retention_seconds  = 345600           # 4 days
  receive_wait_time_seconds  = 10               # Long polling

  # Visibility timeout should be high because Monte Carlo + LLM inference takes time
  visibility_timeout_seconds = 300              # 5 minutes for the GPU to process before returning to queue

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.portfolio_dlq.arn
    maxReceiveCount     = 3
  })
}
