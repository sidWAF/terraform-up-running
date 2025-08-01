# backend.tf (static configuration)
# terraform {
#   backend "s3" {
#     bucket = "your-tf-state-bucket"  # Verify this exists in ap-south-1
#     key    = "terraform.tfstate"
#     region = "ap-south-1"

#     # New locking configuration syntax
#     locking {
#       enabled = true
#       table   = "terraform-locks"  # Must exist in same region
#     }

#     encrypt = true
#   }
# }