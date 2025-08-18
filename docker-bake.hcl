group "default" {
  targets = ["testsuite-pipelines-tools"]
}

variable "TAG" {
  validation {
    condition = TAG == regex("^[0-9]+.[0-9]+", TAG)
    error_message = "TAG must be in a version format x.y for example 0.1"
  }
}

target "testsuite-pipelines-tools" {
  no-cache = true
  tags = ["quay.io/kuadrant/testsuite-pipelines-tools:latest", "quay.io/kuadrant/testsuite-pipelines-tools:${TAG}"]
  platforms = ["linux/amd64", "linux/arm64"]
  output = ["type=registry"]
}
