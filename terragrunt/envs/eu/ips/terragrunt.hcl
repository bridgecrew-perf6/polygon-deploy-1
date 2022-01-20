terraform {
  source = "tfr:///terraform-google-modules/address/google?version=3.1.0"
}

dependency "vpc" {
  config_path = "../../vpc"
  mock_outputs = {
    network_name = "vpc-network-name"
  }
}

include {
  path = find_in_parent_folders()
}

inputs = {
  project_id = "helix-new-polygon"
  network_name = dependency.vpc.outputs.network.network.id
  address_type = "EXTERNAL"
  global = false
  region = "europe-west4"
  names = ["eu-ingress"]
}