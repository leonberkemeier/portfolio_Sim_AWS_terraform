# Identity string for SES - verified sender email address
# Note: You will need to click a verification link sent to this email
# before SES will let you send emails from it.
resource "aws_ses_email_identity" "noreply" {
  email = "noreply@yourdomain.com" # Replace with your actual verified email
}

# Output the ARN so the Layer 3 Backend knows what identity to use when calling the AWS SDK
output "ses_identity_arn" {
  value = aws_ses_email_identity.noreply.arn
}
