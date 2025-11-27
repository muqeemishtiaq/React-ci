pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKER_IMAGE_FRONTEND = 'muqeem112/react-frontend'
        DOCKER_IMAGE_BACKEND = 'muqeem112/react-backend'
        VM_IP = '20.205.24.111'
        SSH_CREDENTIALS = credentials('azure-vm-ssh')
    }
    
    stages {
        stage('Checkout') {
            steps {
                git(
                    url: 'https://github.com/muqeemishtiaq/React-ci.git',
                    credentialsId: 'github-credentials', // Add your GitHub credentials ID
                    branch: 'main'
                )
            }
        }
        
        stage('Build Docker Images') {
            parallel {
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
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    // Add your actual test commands here
                    sh 'echo "Running frontend tests..."'
                    sh 'echo "Running backend tests..."'
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS) {
                        docker.image("${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}").push()
                        docker.image("${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}").push()
                        // Also push as latest
                        docker.image("${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}").push('latest')
                        docker.image("${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}").push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to Azure VM') {
            steps {
                script {
                    sshagent([SSH_CREDENTIALS]) {
                        // Create deployment script on the fly
                        writeFile file: 'deploy.sh', text: """
                            #!/bin/bash
                            BUILD_NUMBER=\$1
                            echo "Deploying build \$BUILD_NUMBER"
                            
                            # Pull latest images
                            docker pull muqeem112/react-frontend:\$BUILD_NUMBER
                            docker pull muqeem112/react-backend:\$BUILD_NUMBER
                            
                            # Stop and remove existing containers
                            docker-compose down || true
                            
                            # Start new containers
                            docker-compose up -d
                            
                            # Clean up old images
                            docker image prune -f
                        """
                        
                        // Copy files to VM
                        sh """
                            scp -o StrictHostKeyChecking=no docker-compose.yml ${SSH_CREDENTIALS_USR}@${VM_IP}:/tmp/
                            scp -o StrictHostKeyChecking=no deploy.sh ${SSH_CREDENTIALS_USR}@${VM_IP}:/tmp/
                        """
                        
                        // Execute deployment
                        sh """
                            ssh -o StrictHostKeyChecking=no ${SSH_CREDENTIALS_USR}@${VM_IP} '
                                cd /tmp &&
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
            sh "echo 'Frontend: http://${VM_IP}'"
            sh "echo 'Backend API: http://${VM_IP}:5000'"
        }
        failure {
            echo 'Deployment failed! Check the logs above for errors.'
        }
    }
}