module "listener_rule_home" {
  source = "github.com/mergermarket/tf_alb_listener_rules"

  alb_listener_arn = "${var.alb_listener_arn}"
  target_group_arn = "${module.service.target_group_arn}"

  host_condition    = "${var.host_condition}"
  path_conditions   = ["${var.path_conditions}"]
  starting_priority = "${var.alb_listener_rule_priority}"
}

module "ecs_update_monitor" {
  source = "github.com/mergermarket/tf_ecs_update_monitor"

  cluster = "${var.ecs_cluster}"
  service = "${module.service.name}"
  taskdef = "${module.taskdef.arn}"
}

module "service" {
  source = "github.com/mergermarket/tf_load_balanced_ecs_service"
  
  name            = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}"
  cluster         = "${var.ecs_cluster}"
  task_definition = "${module.taskdef.arn}"
  vpc_id          = "${var.platform_config["vpc"]}"
  container_name  = "${lookup(var.release, "component")}${var.name_suffix}"
  container_port  = "${var.port}"
  desired_count   = "${var.desired_count}"
}

module "taskdef" {
  source = "github.com/mergermarket/tf_ecs_task_definition"

  family                = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}"
  container_definitions = ["${module.service_container_definition.rendered}"]
}

module "service_container_definition" {
  source = "github.com/mergermarket/tf_ecs_container_definition.git"

  name           = "${lookup(var.release, "component")}${var.name_suffix}"
  image          = "${lookup(var.release, "image_id")}"
  cpu            = "${var.cpu}"
  memory         = "${var.memory}"
  container_port = "${var.port}"

  container_env  = "${merge(
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
}

resource "aws_cloudwatch_log_group" "stdout" {
  name              = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-stdout"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_group" "stderr" {
  name              = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-stderr"
  retention_in_days = "7"
}
