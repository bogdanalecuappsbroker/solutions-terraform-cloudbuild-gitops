terraform {
  source = "../../modules/vpc/"

}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders("org.hcl")
}

