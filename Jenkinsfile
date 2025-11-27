pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKER_IMAGE_FRONTEND = 'muqeem112/react-frontend'
        DOCKER_IMAGE_BACKEND = 'muqeem112/react-backend'
        VM_IP = '20.205.24.111'
        SSH_CREDENTIALS = credentials('azure-vm-ssh')
    }
    
    stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],  
                    extensions: [],
                    userRemoteConfigs: [[
                        credentialsId: 'your-github-credentials',
                        url: 'https://github.com/muqeemishtiaq/React-ci.git'
                    ]]
                ])
            }
        }
        
        stage('Build Frontend') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}", "-f frontend/Dockerfile ./frontend")
                }
            }
        }
        
        stage('Build Backend') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}", "-f backend/Dockerfile ./backend")
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    sh 'echo "Running tests..."'
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('', DOCKERHUB_CREDENTIALS) {
                        docker.image("${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}").push()
                        docker.image("${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}").push()
                    }
                }
            }
        }
        
        stage('Deploy to Azure VM') {
            steps {
                script {
                    sshagent([SSH_CREDENTIALS]) {
                        sh """
                            scp -o StrictHostKeyChecking=no docker-compose.yml ${SSH_CREDENTIALS_USR}@${VM_IP}:/home/${SSH_CREDENTIALS_USR}/
                            scp -o StrictHostKeyChecking=no deploy.sh ${SSH_CREDENTIALS_USR}@${VM_IP}:/home/${SSH_CREDENTIALS_USR}/
                        """
                        
                        sh """
                            ssh -o StrictHostKeyChecking=no ${SSH_CREDENTIALS_USR}@${VM_IP} '
                                cd /home/${SSH_CREDENTIALS_USR} &&
                                chmod +x deploy.sh &&
                                ./deploy.sh ${BUILD_NUMBER}
                            '
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
        success {
            echo 'Deployment completed successfully!'
            sh "echo 'Application deployed: http://${VM_IP}'"
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}