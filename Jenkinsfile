pipeline {
  agent any

  parameters {
    choice(name: 'ACTION', choices: ['apply','destroy'], description: 'apply/destroy')
    string(name: 'VM_NUMBERS', defaultValue: '1', description: 'Numery VM, np. "1,3" lub "2-4"')
  }

  environment {
    TF_VAR_proxmox_api_token = credentials('proxmox_api_token')
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Init') {
      steps {
        // terraform init — backend.tf już wskazuje na state/centos/terraform.tfstate
        sh 'terraform init -reconfigure'
      }
    }

    stage('Plan & Apply/Destroy') {
      steps {
        script {
          // Parsowanie VM_NUMBERS
          def nums = []
          params.VM_NUMBERS.tokenize(',').each { p ->
            if (p.contains('-')) {
              def (f,t) = p.split('-').collect { it.toInteger() }
              nums += (f..t)
            } else {
              nums << p.toInteger()
            }
          }
          def listHCL = nums.join(',')

          if (params.ACTION == 'apply') {
            sh """
              terraform plan -var="vm_numbers=[${listHCL}]" -out=tfplan
              terraform apply -auto-approve tfplan
            """
          } else {
            sh """
              terraform plan -destroy -var="vm_numbers=[${listHCL}]" -out=tfplan
              terraform apply -auto-approve tfplan
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
