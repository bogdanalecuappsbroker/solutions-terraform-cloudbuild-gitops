remote_state {
  backend = "gcs"

  # Same state bucket for for all envs
  config = {
    project = "ab-bogdana-playground"
    bucket  = "ab-bogdana-playground-tfstate123"
    prefix  = "${path_relative_to_include()}/terraform.tfstate"
  }
}

