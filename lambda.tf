#Application decoupling
data "archive_file" "sqs_trigger_lambda" {
  type        = "zip"
  source_file = "${path.module}/example_lambda.py"
  output_path = "${path.module}/example_lambda.py.zip"
}

resource "aws_lambda_function" "sqs_trigger_lambda" {
  function_name = "sqs_trigger_lambda"
  handler = "example_lambda.Handler"
  role = aws_iam_role.example_lambda.arn
  runtime = "python3.8"

  filename = "${data.archive_file.sqs_trigger_lambda.output_path}"
  source_code_hash = "${data.archive_file.sqs_trigger_lambda.output_base64sha256}"

  timeout = 30
  memory_size = 128
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  batch_size        = 1
  event_source_arn  = "${aws_sqs_queue.FirstQueue.arn}" 
  enabled           = true
  function_name     = "${aws_lambda_function.sqs_trigger_lambda.arn}"
}


resource "aws_iam_role" "example_lambda" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "example_lambda" {
  policy_arn = "${aws_iam_policy.example_lambda.arn}"
  role = "${aws_iam_role.example_lambda.name}"
}

resource "aws_iam_policy" "example_lambda" {
  policy = "${data.aws_iam_policy_document.example_lambda.json}"
}

data "aws_iam_policy_document" "example_lambda" {
  statement {
    sid       = "AllowSQSPermissions"
    effect    = "Allow"
    resources = ["arn:aws:sqs:*"]

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
  }

  statement {
    sid       = "AllowInvokingLambdas"
    effect    = "Allow"
    resources = ["arn:aws:lambda:us-east-2:*:function:*"]
    actions   = ["lambda:InvokeFunction"]
  }

  statement {
    sid       = "AllowCreatingLogGroups"
    effect    = "Allow"
    resources = ["arn:aws:logs:us-east-2:*:*"]
    actions   = ["logs:CreateLogGroup"]
  }
  statement {
    sid       = "AllowWritingLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:us-east-2:*:log-group:/aws/lambda/*:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

