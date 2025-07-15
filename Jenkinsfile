pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Wybierz akcję Terraform')
        string(name: 'VM_NUMBERS', defaultValue: '1', description: 'Podaj numery maszyn oddzielone przecinkami lub zakresy, np. "1,3,5" albo "2-4,6"')
    }

    environment {
        TF_VAR_proxmox_api_token = credentials('proxmox_api_token')
    }

    stages {
        stage('Restore Terraform State') {
            steps {
                script {
                    def statePath = "${env.WORKSPACE}/state/terraform.tfstate"
                    if (fileExists(statePath)) {
                        sh "cp \"${statePath}\" ."
                        echo "Stan Terraform został przywrócony z ${statePath}"
                    } else {
                        echo "Brak zapisanego terraform.tfstate – start od zera."
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                echo "Inicjalizacja Terraform z migracją backendu..."
                sh "terraform init -migrate-state -input=false"
            }
        }

        stage('Terraform Apply or Destroy') {
            steps {
                script {
                    def expandedNumbers = []

                    params.VM_NUMBERS.tokenize(',').each { part ->
                        if (part.contains('-')) {
                            def parts = part.split('-')
                            def start = parts[0].toInteger()
                            def end = parts[1].toInteger()
                            expandedNumbers += (start..end)
                        } else {
                            expandedNumbers << part.toInteger()
                        }
                    }

                    def machines = expandedNumbers.collect { num ->
                        return String.format("vmcossz%02d", num)
                    }

                    for (machine in machines) {
                        echo "=== ${params.ACTION.toUpperCase()} dla maszyny ${machine} ==="
                        if (params.ACTION == 'apply') {
                            sh "terraform apply -auto-approve -target=module.${machine}"
                        } else if (params.ACTION == 'destroy') {
                            sh "terraform destroy -auto-approve -target=module.${machine}"
                        }
                        sleep(time: 5, unit: 'SECONDS')
                    }
                }
            }
        }

        stage('Save Terraform State') {
            steps {
                script {
                    def savePath = "${env.WORKSPACE}/state"
                    sh "mkdir -p \"${savePath}\""
                    if (fileExists('terraform.tfstate')) {
                        sh "cp terraform.tfstate \"${savePath}/\""
                        archiveArtifacts artifacts: 'state/terraform.tfstate', fingerprint: true
                        echo "Stan Terraform został zapisany do ${savePath}"
                    } else {
                        echo "Brak terraform.tfstate do zapisania."
                    }
                }
            }
        }
    }
}
