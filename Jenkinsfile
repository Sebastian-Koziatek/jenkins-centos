pipeline {
  agent any

  parameters {
    choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'apply = tworzenie/aktualizacja, destroy = usunięcie')
    string(name: 'VM_NUMBERS', defaultValue: '1', description: 'Numery maszyn, np. "1,3" lub "2-4"')
  }

  environment {
    TF_VAR_proxmox_api_token = credentials('proxmox_api_token')
    TF_BACKEND_BUCKET        = 'moja-terraform-states'
    TF_BACKEND_KEY           = 'centos/terraform.tfstate'
    TF_BACKEND_REGION        = 'eu-central-1'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init') {
      steps {
        sh """
          terraform init \
            -backend-config="bucket=${TF_BACKEND_BUCKET}" \
            -backend-config="key=${TF_BACKEND_KEY}" \
            -backend-config="region=${TF_BACKEND_REGION}" \
            -reconfigure
        """
      }
    }

    stage('Terraform Plan') {
      steps {
        sh 'terraform plan -out=tfplan'
      }
    }

    stage('Terraform Apply/Destroy') {
      steps {
        script {
          // Parsowanie VM_NUMBERS
          def nums = []
          params.VM_NUMBERS.tokenize(',').each { part ->
            if (part.contains('-')) {
              def (from, to) = part.split('-').collect { it.toInteger() }
              nums += (from..to)
            } else {
              nums << part.toInteger()
            }
          }

          // Generacja nazw modułów CentOS
          def modules = nums.collect { n ->
            String.format("vmcentossz%02d", n)
          }

          if (params.ACTION == 'apply') {
            // pełne apply – tworzy wszystko, co brakujące
            sh 'terraform apply -auto-approve tfplan'
          } else {
            // destroy tylko wskazanych modułów
            modules.each { m ->
              echo "=== DESTROY modułu ${m} ==="
              sh "terraform destroy -auto-approve -target=module.${m}"
            }
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'tfplan', allowEmptyArchive: true
    }
  }
}
