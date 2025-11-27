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
        
        stage('Verify Files and Structure') {
            steps {
                script {
                    echo "=== Checking Repository Structure ==="
                    sh '''
                        echo "Current directory:"
                        pwd
                        echo "Listing all files:"
                        ls -la
                        
                        echo "=== Frontend Directory ==="
                        ls -la frontend/
                        echo "Frontend Dockerfile exists:" 
                        test -f frontend/Dockerfile && echo "YES" || echo "NO"
                        
                        echo "=== Backend Directory ==="
                        ls -la backend/
                        echo "Backend Dockerfile exists:"
                        test -f backend/Dockerfile && echo "YES" || echo "NO"
                        
                        echo "=== Dockerfile Contents ==="
                        echo "Frontend Dockerfile:"
                        cat frontend/Dockerfile
                        echo "Backend Dockerfile:"
                        cat backend/Dockerfile
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
                    // Add your test commands here
                    sh "echo 'Tests would run here'"
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'DOCKERHUB_CREDENTIALS',
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
                        credentialsId: 'SSH_CREDENTIALS', 
                        usernameVariable: 'SSH_USERNAME',
                        keyFileVariable: 'SSH_KEY'
                    )]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no -i \$SSH_KEY \$SSH_USERNAME@your-azure-vm-ip '
                                cd /path/to/your/app &&
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
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}