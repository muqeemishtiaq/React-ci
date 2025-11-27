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
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],  
                    extensions: [],
                    userRemoteConfigs: [[
                        credentialsId: 'Github',  // ← Changed to match your credential ID
                        url: 'https://github.com/muqeemishtiaq/React-ci.git'
                    ]]
                ])
            }
        }
        
        stage('Verify Files') {
            steps {
                script {
                    // Check if required files exist
                    sh '''
                        echo "Checking repository structure..."
                        ls -la
                        echo "Frontend directory:"
                        ls -la frontend/ || echo "Frontend directory not found"
                        echo "Backend directory:"
                        ls -la backend/ || echo "Backend directory not found"
                    '''
                }
            }
        }
        
        stage('Build Frontend') {
            steps {
                script {
                    // First check if Dockerfile exists
                    sh 'test -f frontend/Dockerfile && echo "Dockerfile found" || echo "Dockerfile missing"'
                    
                    // Build the Docker image
                    docker.build("${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}", "./frontend")
                }
            }
        }
        
        stage('Build Backend') {
            steps {
                script {
                    // First check if Dockerfile exists
                    sh 'test -f backend/Dockerfile && echo "Dockerfile found" || echo "Dockerfile missing"'
                    
                    // Build the Docker image
                    docker.build("${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}", "./backend")
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    sh 'echo "Running tests..."'
                    // Add your actual test commands here
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