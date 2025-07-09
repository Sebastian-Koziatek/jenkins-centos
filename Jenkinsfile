pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Wybierz akcję Terraform')
        string(name: 'VM_NUMBERS', defaultValue: '1', description: 'Podaj numery maszyn oddzielone przecinkami lub zakresy, np. "1,3,5" albo "2-4,6"')
    }

    environment {
        // Token Proxmox przekazywany do Terraform jako TF_VAR_proxmox_api_token
        TF_VAR_proxmox_api_token = credentials('proxmox_api_token')
        // Ścieżka do oddzielnego katalogu stanu dla CentOS
        CENTOS_STATE_DIR  = "${env.WORKSPACE}/state/centos"
        CENTOS_STATE_FILE = "${CENTOS_STATE_DIR}/terraform.tfstate"
    }

    stages {
        stage('Restore Terraform State') {
            steps {
                script {
                    if (fileExists(CENTOS_STATE_FILE)) {
                        // Przywracamy poprzedni stan CentOS
                        sh "cp \"${CENTOS_STATE_FILE}\" ./terraform.tfstate"
                        echo "Przywrócono stan CentOS z ${CENTOS_STATE_FILE}"
                    } else {
                        echo "Brak zapisanego stanu CentOS – rozpoczęcie od zera."
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                // Inicjalizacja Terraform; -reconfigure wymusza ponowne odczytanie backendu
                sh "terraform init -reconfigure"
            }
        }

        stage('Terraform Apply or Destroy') {
            steps {
                script {
                    // Rozbijamy parametr VM_NUMBERS na listę pojedynczych numerów
                    def expanded = []
                    params.VM_NUMBERS.tokenize(',').each { part ->
                        if (part.contains('-')) {
                            def (from, to) = part.split('-').collect { it.toInteger() }
                            expanded += (from..to)
                        } else {
                            expanded << part.toInteger()
                        }
                    }

                    // Generujemy nazwy modułów dla CentOS – prefix "vmcentossz"
                    def machines = expanded.collect { num ->
                        String.format("vmcentossz%02d", num)
                    }

                    // Wykonujemy apply lub destroy na poszczególnych modułach
                    machines.each { machine ->
                        echo "=== ${params.ACTION.toUpperCase()} dla modułu ${machine} ==="
                        sh "terraform ${params.ACTION} -auto-approve -target=module.${machine}"
                        sleep time: 5, unit: 'SECONDS'
                    }
                }
            }
        }

        stage('Save Terraform State') {
            steps {
                script {
                    // Tworzymy katalog stanu, jeśli nie istnieje
                    sh "mkdir -p \"${CENTOS_STATE_DIR}\""
                    if (fileExists('terraform.tfstate')) {
                        // Zapisujemy nowy stan do oddzielnego katalogu CentOS
                        sh "cp terraform.tfstate \"${CENTOS_STATE_FILE}\""
                        archiveArtifacts artifacts: "state/centos/terraform.tfstate", fingerprint: true
                        echo "Zapisano stan CentOS do ${CENTOS_STATE_FILE}"
                    } else {
                        echo "Brak terraform.tfstate do zapisania."
                    }
                }
            }
        }
    }
}
