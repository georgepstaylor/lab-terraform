resource "aws_sesv2_email_identity" "ses_george_dev" {
  email_identity         = "george.dev"
  configuration_set_name = aws_sesv2_configuration_set.this.configuration_set_name
}

resource "aws_sesv2_configuration_set" "this" {
  configuration_set_name = "george_dev"
}

resource "aws_sesv2_email_identity_mail_from_attributes" "ses_george_dev" {
  email_identity         = aws_sesv2_email_identity.ses_george_dev.id
  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
  mail_from_domain       = "ses.${aws_sesv2_email_identity.ses_george_dev.email_identity}"
}

resource "cloudflare_record" "ses_george_dev_mx" {
  name     = "ses.${aws_sesv2_email_identity.ses_george_dev.email_identity}"
  proxied  = false
  ttl      = 1
  type     = "MX"
  priority = 10
  value    = "feedback-smtp.eu-west-2.amazonses.com"
  zone_id  = data.cloudflare_zone.george_dev.id
}

resource "cloudflare_record" "ses_george_dev_dkim" {
  count   = 3
  name    = "${aws_sesv2_email_identity.ses_george_dev.dkim_signing_attributes.0.tokens[count.index]}._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = "${aws_sesv2_email_identity.ses_george_dev.dkim_signing_attributes.0.tokens[count.index]}.dkim.amazonses.com"
  zone_id = data.cloudflare_zone.george_dev.id

}

# resource "cloudflare_record" "ses_george_dev_dmarc" {
#   name    = "_dmarc"
#   proxied = false
#   ttl     = 1
#   type    = "TXT"
#   value   = "v=DMARC1; p=none"
#   zone_id = data.cloudflare_zone.george_dev.id
# }

#####################
# SES SMTP User
#####################

resource "aws_iam_user" "george_dev_ses_smtp_user" {
  name = "george-dev-smtp-user"
}

resource "aws_iam_access_key" "george_dev_ses_smtp_user" {
  user = aws_iam_user.george_dev_ses_smtp_user.name
}

resource "aws_iam_user_policy" "george_dev_ses_smtp_user" {
  name = "george-dev-ses-smtp-user-policy"
  user = aws_iam_user.george_dev_ses_smtp_user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ses:SendRawEmail",
          "ses:SendEmail"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_ssm_parameter" "george_dev_ses_smtp_user" {
  name = "/george_dev/ses_smtp"
  type = "SecureString"
  value = jsonencode({
    user              = aws_iam_user.george_dev_ses_smtp_user.name,
    key               = aws_iam_access_key.george_dev_ses_smtp_user.id,
    secret            = aws_iam_access_key.george_dev_ses_smtp_user.secret
    ses_smtp_user     = aws_iam_access_key.george_dev_ses_smtp_user.id
    ses_smtp_password = aws_iam_access_key.george_dev_ses_smtp_user.ses_smtp_password_v4
  })
}


########################
# SES CloudWatch Alarms
########################

resource "aws_sns_topic" "ses_george_dev" {
  name = "ses-george-dev"
}
resource "aws_cloudwatch_metric_alarm" "ses_george_dev_send_hourly" {
  alarm_name          = "ses-george-dev-send-hourly"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Send"
  namespace           = "AWS/SES"
  period              = 3600
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "Alarm when the number of emails sent in the last hour exceeds 100"
  alarm_actions       = [aws_sns_topic.shhmas_alerts.arn]
  ok_actions = [aws_sns_topic.shhmas_alerts.arn]
}


