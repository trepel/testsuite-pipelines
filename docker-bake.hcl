group "default" {
  targets = ["testsuite-pipelines-tools"]
}

variable "VERSION" {
  validation {
    condition = VERSION == "" || can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", VERSION))
    error_message = "VERSION must be in semantic format - for example v0.0.1"
  }
}

variable "OUTPUT" {
  default = "type=image"
}

target "testsuite-pipelines-tools" {
  no-cache = true
  tags = compact(concat(
      ["quay.io/kuadrant/testsuite-pipelines-tools:latest"],
      VERSION != "" ? ["quay.io/kuadrant/testsuite-pipelines-tools:${VERSION}"] : []
    ))
  platforms = ["linux/amd64", "linux/arm64"]
  output = [OUTPUT]
}
