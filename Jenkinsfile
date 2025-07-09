pipeline {
  agent any

  parameters {
    choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Wybierz akcję Terraform')
    string(name: 'VM_NUMBERS', defaultValue: '1', description: 'Numery maszyn, np. "1,3" lub "2-4"')
  }

  environment {
    TF_VAR_proxmox_api_token = credentials('proxmox_api_token')
    CENTOS_STATE_DIR        = "${env.WORKSPACE}/state/centos"
    CENTOS_STATE_FILE       = "${CENTOS_STATE_DIR}/terraform.tfstate"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Ensure State Dir') {
      steps {
        sh "mkdir -p \"${CENTOS_STATE_DIR}\""
      }
    }

    stage('Terraform Init') {
      steps {
        sh "terraform init -reconfigure"
      }
    }

    stage('Terraform Plan & Apply/Destroy') {
      steps {
        script {
          // 1) Parsowanie VM_NUMBERS na listę cyfr
          def nums = []
          params.VM_NUMBERS.tokenize(',').each { part ->
            if (part.contains('-')) {
              def (from, to) = part.split('-').collect { it.toInteger() }
              nums += (from..to)
            } else {
              nums << part.toInteger()
            }
          }

          // 2) Tworzymy listę modułów (prefix vmcentosszXX)
          def modules = nums.collect { n ->
            String.format("vmcentossz%02d", n)
          }

          // 3) Dla każdego modułu: plan z -wskazaniem stanu, apply z jego aktualizacją
          modules.each { m ->
            echo "=== ${params.ACTION.toUpperCase()} modułu ${m} ==="
            sh """
              terraform plan \
                -state=${CENTOS_STATE_FILE} \
                -out=tfplan \
                -target=module.${m}

              terraform ${params.ACTION} \
                -state=${CENTOS_STATE_FILE} \
                -state-out=${CENTOS_STATE_FILE} \
                -auto-approve tfplan
            """
            sleep 5
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: "state/centos/terraform.tfstate, tfplan", allowEmptyArchive: true
    }
  }
}
