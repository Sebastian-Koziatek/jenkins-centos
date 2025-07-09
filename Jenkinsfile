pipeline {
  agent any

  parameters {
    choice(name: 'ACTION',
           choices: ['apply','destroy'],
           description: 'apply = tworzenie/aktualizacja, destroy = usunięcie')
    string(name: 'VM_NUMBERS',
           defaultValue: '1',
           description: 'Lista numerów maszyn, np. "1", "1,3" lub "2-4"')
  }

  environment {
    // Proxmox API token do Terraform
    TF_VAR_proxmox_api_token = credentials('proxmox_api_token')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Init') {
      steps {
        // inicjalizacja local backendu z automatyczną migracją stanu
        sh 'terraform init -reconfigure -input=false -force-copy'
      }
    }

    stage('Plan & Apply/Destroy') {
      steps {
        script {
          // Parsowanie VM_NUMBERS na listę numerów
          def nums = []
          params.VM_NUMBERS.tokenize(',').each { part ->
            if (part.contains('-')) {
              def (a, b) = part.split('-').collect { it.toInteger() }
              nums += (a..b)
            } else {
              nums << part.toInteger()
            }
          }
          def hclList = nums.join(',')

          if (params.ACTION == 'apply') {
            // plan + apply tylko dla wskazanych VM
            sh """
              terraform plan \\
                -var="vm_numbers=[${hclList}]" \\
                -out=tfplan

              terraform apply \\
                -auto-approve tfplan
            """
          } else {
            // plan -destroy + apply (destroy) tylko dla wskazanych VM
            sh """
              terraform plan \\
                -destroy \\
                -var="vm_numbers=[${hclList}]" \\
                -out=tfplan

              terraform apply \\
                -auto-approve tfplan
            """
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
