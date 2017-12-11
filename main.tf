module "ecs_update_monitor" {
  source = "github.com/mergermarket/tf_ecs_update_monitor"

  cluster = "${var.ecs_cluster}"
  service = "${module.service.name}"
  taskdef = "${module.taskdef.arn}"
}

module "service" {
  source = "github.com/mergermarket/tf_load_balanced_ecs_service?ref=no-target-group"

  name             = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}"
  cluster          = "${var.ecs_cluster}"
  task_definition  = "${module.taskdef.arn}"
  container_name   = "${lookup(var.release, "component")}${var.name_suffix}"
  container_port   = "${var.port}"
  desired_count    = "${var.desired_count}"
  target_group_arn = "${var.target_group_arn}"
}

module "taskdef" {
  source = "github.com/mergermarket/tf_ecs_task_definition_with_task_role"

  family                = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}"
  container_definitions = ["${module.service_container_definition.rendered}"]
  policy                = "${var.task_role_policy}"
}

module "service_container_definition" {
  source = "github.com/mergermarket/tf_ecs_container_definition.git"

  name           = "${lookup(var.release, "component")}${var.name_suffix}"
  image          = "${lookup(var.release, "image_id")}"
  cpu            = "${var.cpu}"
  memory         = "${var.memory}"
  container_port = "${var.port}"

  container_env = "${merge(
    map(
      "LOGSPOUT_CLOUDWATCHLOGS_LOG_GROUP_STDOUT", "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-stdout",
      "LOGSPOUT_CLOUDWATCHLOGS_LOG_GROUP_STDERR", "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-stderr",
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

  labels {
    component          = "${lookup(var.release, "component")}"
    env                = "${var.env}"
    team               = "${lookup(var.release, "team")}"
    version            = "${lookup(var.release, "version")}"
    "logentries.token" = "${var.logentries_token}"
  }
}

resource "aws_cloudwatch_log_group" "stdout" {
  name              = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-stdout"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_group" "stderr" {
  name              = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-stderr"
  retention_in_days = "7"
}
