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
                // tworzymy katalog, jeśli nie istnieje
                sh "mkdir -p \"${CENTOS_STATE_DIR}\""
            }
        }

        stage('Terraform Init') {
            steps {
                // inicjalizujemy lokalny backend wskazujący na state/centos/terraform.tfstate
                sh """
                  terraform init -reconfigure \
                    -backend-config="path=${CENTOS_STATE_FILE}"
                """
            }
        }

        stage('Terraform Plan & Apply/Destroy') {
            steps {
                script {
                    // parsowanie zakresów VM_NUMBERS
                    def nums = []
                    params.VM_NUMBERS.tokenize(',').each { part ->
                        if (part.contains('-')) {
                            def (from, to) = part.split('-').collect { it.toInteger() }
                            nums += (from..to)
                        } else {
                            nums << part.toInteger()
                        }
                    }

                    // generacja nazw modułów CentOS
                    def modules = nums.collect { n ->
                        String.format("vmcentossz%02d", n)
                    }

                    // wykonanie apply/destroy
                    modules.each { m ->
                        echo "=== ${params.ACTION.toUpperCase()} modułu ${m} ==="
                        sh "terraform ${params.ACTION} -auto-approve -target=module.${m}"
                        sleep 5
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: "state/centos/terraform.tfstate", allowEmptyArchive: true
        }
    }
}
