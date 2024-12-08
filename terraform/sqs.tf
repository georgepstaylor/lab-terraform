resource "aws_sqs_queue" "email_queue" {
  name                       = "email-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 30
}

# resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
#   event_source_arn = aws_sqs_queue.email_queue.arn
#   function_name    = aws_lambda_function.email_sender.arn
#   batch_size       = 1
#   enabled          = true
# }

# data "aws_iam_policy_document" "email_queue_policy" {
#   statement {
#     effect = "Allow"
#     principals {
#       type        = "AWS"
#       identifiers = ["*"]
#     }
#     actions   = ["sqs:SendMessage"]
#     resources = [aws_sqs_queue.email_queue.arn]
#     condition {
#       test     = "ArnEquals"
#       variable = "aws:SourceArn"
#       values   = [aws_lambda_function.email_sender.arn]
#     }
#   }
# }

resource "aws_sqs_queue_policy" "email_queue_policy" {
  queue_url = aws_sqs_queue.email_queue.id
  policy    = data.aws_iam_policy_document.email_queue_policy.json
}

# resource "aws_iam_role_policy_attachment" "lambda_sqs" {
#   role       = aws_iam_role.lambda_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
# }

#####################
# SQS IAM User
# #####################

resource "aws_iam_user" "shhmas_sqs_user" {
  name = "shhmas-sqs-user"
}

data "aws_iam_policy_document" "shhmas_sqs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [aws_sqs_queue.email_queue.arn]
  }
}

resource "aws_iam_user_policy" "shhmas_sqs_user" {
  name   = "shhmas-sqs-user-policy"
  user   = aws_iam_user.shhmas_sqs_user.name
  policy = data.aws_iam_policy_document.shhmas_sqs_policy.json
}

##########################
# add to 1password vault
# ########################

resource "aws_iam_access_key" "shhmas" {
  user = aws_iam_user.shhmas_sqs_user.name
}


resource "onepassword_item" "AWS_ACCESS_KEY_SQS" {
  vault    = "lab"
  category = "login"
  username = aws_iam_user.shhmas_sqs_user.name
  password = aws_iam_access_key.shhmas.secret
  title    = "AWS_ACCESS_KEY_SQS"
}
