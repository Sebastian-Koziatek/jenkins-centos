pipeline {
    agent any
    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Wybierz akcję Terraform')
        choice(name: 'VM_NAME', choices: [
            'vmcossz01', 'vmcossz02', 'vmcossz03', 'vmcossz04',
            'vmcossz05', 'vmcossz06', 'vmcossz07', 'vmcossz08',
            'vmcossz09', 'vmcossz10', 'vmcossz11', 'vmcossz12',
            'vmcossz13', 'vmcossz14', 'vmcossz15', 'ALL'
        ], description: 'Wybierz maszynę do operacji')
    }
    environment {
        TF_VAR_proxmox_api_token = credentials('proxmox_api_token')
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: 'github', url: 'git@github.com:Sebastian-Koziatek/jenkins-zabbix-agent.git'
            }
        }

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
                sh "terraform init -reconfigure"
            }
        }

        stage('Terraform Apply or Destroy') {
            steps {
                script {
                    def machines = [
                        'vmcossz01', 'vmcossz02', 'vmcossz03', 'vmcossz04',
                        'vmcossz05', 'vmcossz06', 'vmcossz07', 'vmcossz08',
                        'vmcossz09', 'vmcossz10', 'vmcossz11', 'vmcossz12',
                        'vmcossz13', 'vmcossz14', 'vmcossz15'
                    ]
                    if (params.VM_NAME == 'ALL') {
                        for (machine in machines) {
                            echo "=== ${params.ACTION.toUpperCase()} dla maszyny ${machine} ==="
                            if (params.ACTION == 'apply') {
                                sh "terraform apply -auto-approve -target=proxmox_vm_qemu.${machine}"
                            } else if (params.ACTION == 'destroy') {
                                sh "terraform destroy -auto-approve -target=proxmox_vm_qemu.${machine}"
                            }
                            sleep(time: 15, unit: 'SECONDS')
                        }
                    } else {
                        echo "=== ${params.ACTION.toUpperCase()} dla maszyny ${params.VM_NAME} ==="
                        if (params.ACTION == 'apply') {
                            sh "terraform apply -auto-approve -target=proxmox_vm_qemu.${params.VM_NAME}"
                        } else if (params.ACTION == 'destroy') {
                            sh "terraform destroy -auto-approve -target=proxmox_vm_qemu.${params.VM_NAME}"
                        }
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