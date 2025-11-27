pipeline {
    agent any
    environment {
        DOCKER_IMAGE_FRONTEND = "muqeem112/react-frontend"
        DOCKER_IMAGE_BACKEND = "muqeem112/react-backend"
        BUILD_NUMBER = "${env.BUILD_ID}"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Verify and Create Dockerfiles') {
            steps {
                script {
                    echo "=== Checking and Creating Dockerfiles ==="
                    sh '''
                        echo "Current directory:"
                        pwd
                        
                        # Create frontend Dockerfile if missing
                        if [ ! -f frontend/Dockerfile ]; then
                            echo "Creating frontend Dockerfile..."
                            cat > frontend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json .
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
EOF
                        fi
                        
                        # Create backend Dockerfile if missing
                        if [ ! -f backend/Dockerfile ]; then
                            echo "Creating backend Dockerfile..."
                            cat > backend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json .
RUN npm install
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
EOF
                        fi
                    '''
                }
            }
        }
        
        stage('Build Frontend') {
            steps {
                script {
                    echo "Building Frontend Docker image..."
                    sh """
                        cd frontend
                        docker build -t ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} .
                    """
                }
            }
        }
        
        stage('Build Backend') {
            steps {
                script {
                    echo "Building Backend Docker image..."
                    sh """
                        cd backend
                        docker build -t ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} .
                    """
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    echo "Running tests..."
                    sh "echo 'Tests would run here'"
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )]) {
                        sh """
                            docker login -u \$DOCKER_USERNAME -p \$DOCKER_PASSWORD
                            docker push ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}
                            docker push ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}
                        """
                    }
                }
            }
        }
        
      stage('Deploy to Azure VM') {
    steps {
        script {
            withCredentials([sshUserPrivateKey(
                credentialsId: 'azure-vm-ssh',
                usernameVariable: 'SSH_USERNAME',
                keyFileVariable: 'SSH_KEY'
            )]) {
                sh """
                    ssh -o StrictHostKeyChecking=no -i \$SSH_KEY azureuser@20.205.24.111 '
                        cd /home/azureuser/app &&
                        chmod +x deploy.sh &&
                        ./deploy.sh ${BUILD_NUMBER}
                    '
                """
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
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}