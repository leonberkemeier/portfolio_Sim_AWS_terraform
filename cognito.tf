# Amazon Cognito User Pool for Robo-Advisory Client Accounts
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-user-pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Users use their email to log in
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  # Standard attributes we want to collect during onboarding
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
  }
}

# The App Client allows the React frontend to interact with this User Pool
resource "aws_cognito_user_pool_client" "frontend_client" {
  name         = "${var.project_name}-react-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Do not generate a secret for SPAs (React) as it cannot be stored securely
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
}
