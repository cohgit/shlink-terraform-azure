terraform {
  cloud {
    organization = "cogalde"
    
    workspaces {
      name = "shlink-terraform-azure"
    }
  }
}
