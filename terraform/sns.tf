resource "aws_sns_topic" "shhmas_alerts" {
  name = "shhmas-alerts"
}

import {
    to = aws_sns_topic.shhmas_alerts
    id = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:shhmas-alerts"
}
