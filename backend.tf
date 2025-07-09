terraform {
  backend "local" {
    # oddzielny stan dla CentOS
    path = "state/centos/terraform.tfstate"
  }
}
