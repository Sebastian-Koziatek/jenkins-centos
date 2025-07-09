pipeline {
  agent any

  parameters {
    choice(name: 'ACTION',
           choices: ['apply','destroy'],
           description: 'apply = tworzenie/aktualizacja, destroy = usunięcie')
    string(name: 'VM_NUMBERS',
           defaultValue: '1',
           description: 'Numery maszyn, np. "1", "1,3" lub "2-4"')
  }

  environment {
    // Proxmox API token przekazywany do Terraform jako TF_VAR_proxmox_api_token
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
        // Inicjalizacja lokalnego backendu (state/centos/terraform.tfstate)
        // -input=false i -force-copy automatycznie migrują istniejący stan non-interactive
        sh 'terraform init -reconfigure -input=false -force-copy'
      }
    }

    stage('Plan & Apply/Destroy') {
      steps {
        script {
          // 1) Rozbij VM_NUMBERS na listę liczb
          def nums = []
          params.VM_NUMBERS.tokenize(',').each { part ->
            if (part.contains('-')) {
              def (from, to) = part.split('-').collect { it.toInteger() }
              nums += (from..to)
            } else {
              nums << part.toInteger()
            }
          }
          // 2) Zamień na HCL-ową listę, np. [1,3,5]
          def listHCL = nums.join(',')

          if (params.ACTION == 'apply') {
            // Tworzymy/aktualizujemy tylko wskazane VM
            sh """
              terraform plan \
                -var="vm_numbers=[${listHCL}]" \
                -out=tfplan

              terraform apply \
                -auto-approve tfplan
            """
          } else {
            // Niszczenie tylko wskazanych VM
            sh """
              terraform plan \
                -destroy \
                -var="vm_numbers=[${listHCL}]" \
                -out=tfplan

              terraform apply \
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
