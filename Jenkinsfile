pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Wybierz akcję Terraform')
        string(name: 'VM_NUMBERS', defaultValue: '1', description: 'Podaj numery maszyn, np. "1,3" lub "2-4"')
    }

    environment {
        TF_VAR_proxmox_api_token = credentials('proxmox_api_token')
        TF_BACKEND_BUCKET        = 'moja-bucket'
        TF_BACKEND_KEY           = 'terraform/centos/terraform.tfstate'
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

        stage('Terraform Plan & Apply/Destroy') {
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

                    // Generacja nazwy modułu
                    def modules = nums.collect { n ->
                        String.format("vmcentossz%02d", n)
                    }

                    // Dla każdego modułu uruchamiamy apply/destroy
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
            archiveArtifacts artifacts: '*.tfstate, *.tfplan', allowEmptyArchive: true
        }
    }
}
