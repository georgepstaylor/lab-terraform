resource "aws_sqs_queue" "email_queue" {
  name                       = "email-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 900
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_queue_dead_letter.arn,
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "email_queue_dead_letter" {
  name = "email-queue-dead-letter"
}

data "archive_file" "ses_send" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/ses_send"
  output_path = "${path.module}/lambda/ses_send/ses_send.zip"
  excludes    = ["ses_send.zip"]
}

resource "aws_lambda_function" "email_sender" {
  filename         = "${path.module}/lambda/ses_send/ses_send.zip"
  function_name    = "ses_send"
  architectures    = ["arm64"]
  role             = aws_iam_role.ses_send_lambda_role.arn
  runtime          = "python3.12"
  handler          = "ses_send.handler"
  source_code_hash = data.archive_file.ses_send.output_base64sha256

  timeout = 10

  lifecycle {
    replace_triggered_by = [aws_iam_role.ses_send_lambda_role]
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ses_send_lambda_role" {
  name               = "ses_send_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "ses_send_lambda_policy"
  description = "Allows Lambda to send emails via SES"
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.ses_send_lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
  event_source_arn = aws_sqs_queue.email_queue.arn
  function_name    = aws_lambda_function.email_sender.arn
  batch_size       = 1
  enabled          = true
}

data "aws_iam_policy_document" "email_queue_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.email_queue.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_lambda_function.email_sender.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "email_queue_policy" {
  queue_url = aws_sqs_queue.email_queue.id
  policy    = data.aws_iam_policy_document.email_queue_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.ses_send_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

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


data "onepassword_vault" "lab" {
  name = "lab"
}

resource "onepassword_item" "AWS_ACCESS_KEY_SQS" {
  vault    = data.onepassword_vault.lab.uuid
  category = "login"
  username = aws_iam_access_key.shhmas.id
  password = aws_iam_access_key.shhmas.secret
  title    = "AWS_ACCESS_KEY_SQS"
}
