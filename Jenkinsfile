pipeline {
  agent any

  environment {
    // Zakładam, że trzymasz token Proxmox w Jenkinsie pod nazwą "proxmox-token"
    TF_VAR_proxmox_api_token = credentials('proxmox-token')
  }

  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      }
    }

    stage('Restore Terraform State') {
      steps {
        // Przywróć stan z workspace/state
        sh '''
          if [ -f state/terraform.tfstate ]; then
            cp state/terraform.tfstate .
            echo "Stan Terraform został przywrócony."
          else
            echo "Brak pliku stanu — zaczynamy od zera."
          fi
        '''
      }
    }

    stage('Terraform Init') {
      steps {
        sh 'terraform init -reconfigure'
      }
    }

    stage('Terraform Apply') {
      steps {
        // Usuwamy -target, aby Terraform wykonał pełne apply wszystkich modułów
        echo '=== APPLY wszystkich modułów Terraform ==='
        sh 'terraform apply -auto-approve'
      }
    }

    stage('Save Terraform State') {
      steps {
        sh '''
          mkdir -p state
          cp terraform.tfstate state/
          echo "Stan Terraform został zapisany."
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'state/terraform.tfstate', fingerprint: true
        }
      }
    }
  }
}
