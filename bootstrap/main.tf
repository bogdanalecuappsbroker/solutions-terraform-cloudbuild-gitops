provider "google" {
  version = "~> 3.28.0"
}

provider "google-beta" {
  version = "~> 3.12.0"
}

provider "null" {
  version = "~> 2.1"
}

resource "google_storage_bucket" "terraform_bucket" {
  name     = "ab-bogdana-playground-tfstate123"
  project  = "ab-bogdana-playground"
  location = "EU"

  bucket_policy_only = true
  force_destroy      = true

  versioning {
    enabled = true
  }

}


/******************************************
  KMS Keyring
 *****************************************/

resource "google_kms_key_ring" "tf_keyring" {
  project  = "ab-bogdana-playground"
  name     = "tf-keyring"
  location = "europe"
}

/******************************************
  KMS Key
 *****************************************/

resource "google_kms_crypto_key" "tf_key" {
  name     = "tf-key"
  key_ring = google_kms_key_ring.tf_keyring.self_link
}

/******************************************
  Permissions to decrypt.
 *****************************************/

resource "google_kms_crypto_key_iam_binding" "cloudbuild_crypto_key_decrypter" {
  crypto_key_id = google_kms_crypto_key.tf_key.self_link
  role          = "roles/cloudkms.cryptoKeyDecrypter"

  members = [
    "serviceAccount:845387398384@cloudbuild.gserviceaccount.com",
    "serviceAccount:terraform-sa@ab-bogdana-playground.iam.gserviceaccount.com"
  ]
}


resource "google_service_account_iam_member" "cloudbuild_terraform_sa_impersonate_permissions" {
  service_account_id = "projects/ab-bogdana-playground/serviceAccounts/terraform-sa@ab-bogdana-playground.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:845387398384@cloudbuild.gserviceaccount.com"
}

# Required to allow cloud build to access state with impersonation.
resource "google_storage_bucket_iam_member" "cloudbuild_state_iam" {
  bucket = google_storage_bucket.terraform_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:845387398384@cloudbuild.gserviceaccount.com"
}


/***********************************************
 Cloud Build - Terraform builder
 ***********************************************/

resource "null_resource" "cloudbuild_terraform_builder" {
  triggers = {
#    project_id_cloudbuild_project = module.cloudbuild_project.project_id
    terraform_version_sha256sum   = var.terraform_version_sha256sum
    terraform_version             = var.terraform_version
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud builds submit ${path.module}/cloudbuild_builder/ \
      --project ab-bogdana-playground \
      --gcs-source-staging-dir="gs://ab-bogdana-playground-cloudbuild/staging" \
      --config=${path.module}/cloudbuild_builder/cloudbuild.yaml \
      --substitutions=_TERRAFORM_VERSION=${var.terraform_version},_TERRAFORM_VERSION_SHA256SUM=${var.terraform_version_sha256sum}
  EOT
  }
#  depends_on = [
#    google_project_service.cloudbuild_apis,
#  ]
}


/***********************************************
 Cloud Build - Non Master branch triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "non_master_trigger" {
  provider    = google-beta
  project     = "ab-bogdana-playground"
  description = "terragrunt plan on all branches except master."

/*
  trigger_template {
    branch_name = "[^master]"
    repo_name   = "bogdanalecuappsbroker/solutions-terraform-cloudbuild-gitops"
  }
*/

  github {
    owner = "bogdanalecuappsbroker"
    name = "solutions-terraform-cloudbuild-gitops"
    push {
      branch = "[^master]"
    }
  }

  substitutions = {
#    _ORG_ID               = var.org_id
#    _BILLING_ID           = var.billing_account
#    _DEFAULT_REGION       = var.default_region
    _TF_SA_EMAIL          = "terraform-sa@ab-bogdana-playground.iam.gserviceaccount.com"
#    _STATE_BUCKET_NAME    = "ab-bogdana-playground-tfstate123"
    _ARTIFACT_BUCKET_NAME = "ab-bogdana-playground-cloudbuild"
#    _SEED_PROJECT_ID      = "ab-bogdana-playground"
  }

  filename = "cloudbuild-tg-plan.yaml"
  depends_on = [
    null_resource.cloudbuild_terraform_builder,
  ]
}

resource "google_cloudbuild_trigger" "master_trigger" {
  provider    = google-beta
  project     = "ab-bogdana-playground"
  description = "terragrunt apply on master."

  github {
    owner = "bogdanalecuappsbroker"
    name = "solutions-terraform-cloudbuild-gitops"
    pull_request {
      branch = "master"
    }
  }
  substitutions = {
    _TF_SA_EMAIL          = "terraform-sa@ab-bogdana-playground.iam.gserviceaccount.com"
    _ARTIFACT_BUCKET_NAME = "ab-bogdana-playground-cloudbuild"
  }

  filename = "cloudbuild-tg-apply.yaml"
  depends_on = [
    null_resource.cloudbuild_terraform_builder,
  ]
}
