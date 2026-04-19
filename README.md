cat > README.md << 'EOF'
# project infra - Infrastructure

Terraform code for AWS infrastructure.

## Structure
  INFRA REPO        
│  │ (Terraform)          
│  │                    
│  │ /bootstrap         
│  │   └─ S3, DynamoDB    
│  │ /modules             
│  │   ├─ vpc           
│  │   └─ eks            
│  │ /environments        
│  │   ├─ dev             
│  │   └─ prod   

.github/workflows/ # Terraform CI/CD


## Branching Model
- `main` → Protected, requires PR
- Feature branches → Short-lived, <1 day

## Quick Start

```bash
# Dev environment
cd environments/dev
terraform init
terraform plan
terraform apply
EOF