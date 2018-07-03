locals {
  service_name = "${var.env}-${lookup(var.release, "component")}"
}

module "ecs_update_monitor" {
  source = "github.com/mergermarket/tf_ecs_update_monitor"

  cluster = "${var.ecs_cluster}"
  service = "${module.service.name}"
  taskdef = "${module.taskdef.arn}"
}

module "service" {
  source = "github.com/mergermarket/tf_load_balanced_ecs_service?ref=no-target-group"

  name                               = "${local.service_name}${var.name_suffix}"
  cluster                            = "${var.ecs_cluster}"
  task_definition                    = "${module.taskdef.arn}"
  container_name                     = "${lookup(var.release, "component")}${var.name_suffix}"
  container_port                     = "${var.port}"
  desired_count                      = "${var.desired_count}"
  target_group_arn                   = "${var.target_group_arn}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
}

module "taskdef" {
  source = "github.com/mergermarket/tf_ecs_task_definition_with_task_role"

  family                = "${local.service_name}${var.name_suffix}"
  container_definitions = ["${module.service_container_definition.rendered}"]
  policy                = "${var.task_role_policy}"
  assume_role_policy    = "${var.assume_role_policy}"
  volume                = "${var.taskdef_volume}"
}

module "service_container_definition" {
  source = "github.com/mergermarket/tf_ecs_container_definition"

  name               = "${lookup(var.release, "component")}${var.name_suffix}"
  image              = "${lookup(var.release, "image_id")}"
  cpu                = "${var.cpu}"
  memory             = "${var.memory}"
  container_port     = "${var.port}"
  nofile_soft_ulimit = "${var.nofile_soft_ulimit}"
  mountpoint         = "${var.container_mountpoint}"
  port_mappings      = "${var.container_port_mappings}"

  container_env = "${merge(
    map(
      "LOGSPOUT_CLOUDWATCHLOGS_LOG_GROUP_STDOUT", "${local.service_name}${var.name_suffix}-stdout",
      "LOGSPOUT_CLOUDWATCHLOGS_LOG_GROUP_STDERR", "${local.service_name}${var.name_suffix}-stderr",
      "STATSD_HOST", "172.17.42.1",
      "STATSD_PORT", "8125",
      "STATSD_ENABLED", "true",
      "ENV_NAME", "${var.env}",
      "COMPONENT_NAME",  "${lookup(var.release, "component")}",
      "VERSION",  "${lookup(var.release, "version")}"
    ),
    var.common_application_environment,
    var.application_environment,
    var.secrets
  )}"

  labels = "${merge(map(
    "component", var.release["component"],
    "env", var.env,
    "team", var.release["team"],
    "version", var.release["version"],
    "logentries.token", var.logentries_token
  ), var.container_labels)}"
}

resource "aws_cloudwatch_log_group" "stdout" {
  name              = "${local.service_name}${var.name_suffix}-stdout"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_group" "stderr" {
  name              = "${local.service_name}${var.name_suffix}-stderr"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_subscription_filter" "kinesis_log_stdout_stream" {
  count           = "${var.platform_config["datadog_log_subscription_arn"] != "" ? 1 : 0}"
  name            = "kinesis-log-stdout-stream-${local.service_name}"
  destination_arn = "${var.platform_config["datadog_log_subscription_arn"]}"
  log_group_name  = "${local.service_name}${var.name_suffix}-stdout"
  filter_pattern  = ""
}

resource "aws_cloudwatch_log_subscription_filter" "kinesis_log_stderr_stream" {
  count           = "${var.platform_config["datadog_log_subscription_arn"] != "" ? 1 : 0}"
  name            = "kinesis-log-stdout-stream-${local.service_name}"
  destination_arn = "${var.platform_config["datadog_log_subscription_arn"]}"
  log_group_name  = "${local.service_name}${var.name_suffix}-stderr"
  filter_pattern  = ""
}
