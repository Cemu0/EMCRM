# Enhanced lifecycle management for easier cleanup

# Null resource to clean ECR images before destroy
resource "null_resource" "ecr_cleanup" {
  triggers = {
    repository_name = "emcrm-app"
    aws_region     = var.aws_region
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Cleaning up ECR repository images..."
      aws ecr batch-delete-image \
        --repository-name ${self.triggers.repository_name} \
        --region ${self.triggers.aws_region} \
        --image-ids "$(aws ecr list-images --repository-name ${self.triggers.repository_name} --region ${self.triggers.aws_region} --query 'imageIds[*]' --output json 2>/dev/null || echo '[]')" 2>/dev/null || echo "No images to delete or repository already deleted"
    EOT
  }
}

# Null resource to handle OpenSearch domain deletion gracefully
resource "null_resource" "opensearch_cleanup" {
  triggers = {
    domain_name = var.opensearch_domain_name
    aws_region  = var.aws_region
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Preparing OpenSearch domain for deletion..."
      # Check if domain exists and wait for any pending operations
      aws opensearch describe-domain --domain-name ${self.triggers.domain_name} --region ${self.triggers.aws_region} 2>/dev/null || echo "Domain already deleted or doesn't exist"
      
      # Wait a moment for any pending operations
      sleep 10
    EOT
  }
}

# Dependency management
resource "null_resource" "destroy_order" {
  depends_on = [
    null_resource.ecr_cleanup,
    null_resource.opensearch_cleanup
  ]

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Cleanup preparation complete'"
  }
}