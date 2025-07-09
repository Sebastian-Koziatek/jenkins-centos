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

    stage('Per-Module Plan & Apply/Destroy') {
      steps {
        script {
          // 1) Rozbijamy VM_NUMBERS na listę liczb
          def nums = []
          params.VM_NUMBERS.tokenize(',').each { part ->
            if (part.contains('-')) {
              def (from, to) = part.split('-').collect { it.toInteger() }
              nums += (from..to)
            } else {
              nums << part.toInteger()
            }
          }

          // 2) Generujemy nazwy modułów CentOS
          def modules = nums.collect { n ->
            String.format("vmcentossz%02d", n)
          }

          // 3) Dla każdego modułu robimy plan + apply lub destroy
          modules.each { m ->
            echo ">>> ${params.ACTION.toUpperCase()} dla modułu ${m}"
            if (params.ACTION == 'apply') {
              sh """
                terraform plan \
                  -target=module.${m} \
                  -out=tfplan-${m}

                terraform apply \
                  -auto-approve tfplan-${m}
              """
            } else {
              sh """
                terraform plan \
                  -destroy \
                  -target=module.${m} \
                  -out=tfplan-d-${m}

                terraform apply \
                  -auto-approve tfplan-d-${m}
              """
            }
            sleep 5
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'tfplan-*', allowEmptyArchive: true
    }
  }
}
