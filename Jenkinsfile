pipeline {
  agent any

  environment {
    // jeżeli masz inne TF_VAR_, dopisz je tutaj
    TF_LOG = "ERROR"
  }

  stages {
    stage('Checkout SCM') {
      steps {
        checkout([
          $class: 'GitSCM',
          branches: [[name: '*/main']],
          userRemoteConfigs: [[
            url: 'git@github.com:Sebastian-Koziatek/jenkins-centos.git',
            credentialsId: 'jenkins'
          ]]
        ])
      }
    }

    stage('Set Proxmox Credentials') {
      steps {
        withCredentials([string(credentialsId: 'proxmox-token', variable: 'TF_VAR_proxmox_api_token')]) {
          sh 'echo "Proxmox token loaded."'
        }
      }
    }

    stage('Restore Terraform State') {
      steps {
        script {
          if (fileExists('state/terraform.tfstate')) {
            sh 'cp state/terraform.tfstate .'
            echo 'Stan Terraform został przywrócony'
          }
        }
      }
    }

    stage('Terraform Init') {
      steps {
        sh 'terraform init -reconfigure'
      }
    }

    stage('Terraform Plan') {
      steps {
        sh 'terraform plan -out=tfplan'
      }
    }

    stage('Terraform Apply') {
      steps {
        sh 'terraform apply -auto-approve tfplan'
      }
    }

    stage('Save Terraform State') {
      steps {
        sh '''
          mkdir -p state
          cp terraform.tfstate state/
        '''
        archiveArtifacts artifacts: 'state/terraform.tfstate', fingerprint: true
        echo 'Stan Terraform został zapisany'
      }
    }
  }
}
