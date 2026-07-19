module "secrets_manager_api" {
  source = "../../../modules/secrets-manager"

  env     = var.env
  project = var.project

  secret = {
    name       = "/prod/api"
    kms_key_id = data.terraform_remote_state.general.outputs.kms_shared_arn
    secret_string = {
      DB_HOST     = module.aurora.cluster_endpoint
      DB_PORT     = "5432"
      DB_NAME     = data.sops_file.secret_enc.data["DB_NAME"]
      DB_USERNAME = data.sops_file.secret_enc.data["DB_USERNAME"]
      DB_PASSWORD = data.sops_file.secret_enc.data["DB_PASSWORD"]
    }
  }
}
