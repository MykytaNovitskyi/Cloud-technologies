module "notification_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
  context = module.label.context
  name    = "notification"
}

module "notify_slack" {
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "5.6.0"

  sns_topic_name = module.notification_label.id

  lambda_function_name = module.notification_label.id

  slack_webhook_url = var.slack_webhook_url
  slack_channel     = "aws-notification"
  slack_username    = "terraform-reporter"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = module.notify_slack.slack_topic_arn
  protocol  = "email"
  endpoint  = "mykyta.novitskyi.it.2022@lpnu.ua"
}


resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = module.notification_label.id
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors ${module.lambda.lambda_authors_function_name}"
  treat_missing_data  = "notBreaching"
  dimensions = {
    "FunctionName" = "${module.lambda.lambda_authors_function_name}"
  }
  datapoints_to_alarm = 1
  actions_enabled     = "true"
  alarm_actions       = [module.notify_slack.slack_topic_arn]
  ok_actions          = [module.notify_slack.slack_topic_arn]
}