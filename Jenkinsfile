pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Wybierz akcję Terraform')
        string(name: 'VM_NUMBERS', defaultValue: '1', description: 'Numery maszyn oddzielone przecinkami lub zakresy, np. "1,3,5" albo "2-4,6"')
    }

    environment {
        // Token Proxmox przekazywany do Terraform jako TF_VAR_proxmox_api_token
        TF_VAR_proxmox_api_token = credentials('proxmox_api_token')
        // Ścieżka do katalogu stanu dla RHEL
        RHEL_STATE_DIR  = "${env.WORKSPACE}/state/rhel"
        RHEL_STATE_FILE = "${RHEL_STATE_DIR}/terraform.tfstate"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Restore Terraform State') {
            steps {
                script {
                    sh "mkdir -p \"${RHEL_STATE_DIR}\""
                    if (fileExists(RHEL_STATE_FILE)) {
                        sh "cp \"${RHEL_STATE_FILE}\" terraform.tfstate"
                        echo "Przywrócono stan RHEL z ${RHEL_STATE_FILE}"
                    } else {
                        echo "Brak zapisanego stanu RHEL, rozpoczynamy z pustym stanem."  
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init -reconfigure'
            }
        }

        stage('Terraform Apply/Destroy') {
            steps {
                script {
                    // Funkcja do parsowania parametrów VM_NUMBERS
                    def parseList = { str ->
                        def result = []
                        str.split(',').each { part ->
                            if (part.contains('-')) {
                                def (start, end) = part.split('-')*.toInteger()
                                result += (start..end)
                            } else {
                                result << part.toInteger()
                            }
                        }
                        return result
                    }

                    def vms = parseList(params.VM_NUMBERS)

                    if (params.ACTION == 'apply') {
                        // Apply dla wszystkich wskazanych maszyn
                        vms.each { num ->
                            sh "terraform apply -auto-approve -target=module.vmrhelsz${num}"
                        }
                    } else {
                        // Destroy tylko dla wskazanych maszyn
                        vms.each { num ->
                            echo "=== DESTROY dla modułu vmrhelsz${num} ==="
                            sh "terraform destroy -auto-approve -target=module.vmrhelsz${num}.proxmox_virtual_environment_vm.vm"
                        }
                    }
                }
            }
        }

        stage('Save Terraform State') {
            steps {
                script {
                    sh "mkdir -p \"${RHEL_STATE_DIR}\""
                    if (fileExists('terraform.tfstate')) {
                        sh "cp terraform.tfstate \"${RHEL_STATE_FILE}\""
                        archiveArtifacts artifacts: 'state/rhel/terraform.tfstate', fingerprint: true
                        echo "Zapisano stan RHEL do ${RHEL_STATE_FILE}"
                    } else {
                        echo "Brak terraform.tfstate do zapisania."
                    }
                }
            }
        }
    }
}
