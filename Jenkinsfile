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
                                # Check current user and available directories
                                echo "Current user: \$(whoami)"
                                echo "Home directory: \$HOME"
                                echo "Available directories:"
                                ls -la / || echo "Cannot list root"
                                
                                # Try different directory locations
                                if [ -d "/home/azureuser" ]; then
                                    cd /home/azureuser
                                    mkdir -p app
                                    cd app
                                elif [ -d "/opt" ]; then
                                    sudo mkdir -p /opt/app || mkdir -p /tmp/app
                                    cd /opt/app || cd /tmp/app
                                else
                                    mkdir -p /tmp/app
                                    cd /tmp/app
                                fi
                                
                                echo "Working in: \$(pwd)"
                                
                                # Create complete deploy.sh script
                                cat > deploy.sh << \"ENDDEPLOY\"
#!/bin/bash
BUILD_NUMBER=\\\$1
DOCKER_IMAGE_FRONTEND=\"muqeem112/react-frontend\"
DOCKER_IMAGE_BACKEND=\"muqeem112/react-backend\"

echo \"=== Starting Deployment for build: \\\$BUILD_NUMBER ===\"

echo \"Stopping existing containers...\"
docker-compose down || true

echo \"Removing old images...\"
docker rmi \\\${DOCKER_IMAGE_FRONTEND}:\\\${BUILD_NUMBER} || true
docker rmi \\\${DOCKER_IMAGE_BACKEND}:\\\${BUILD_NUMBER} || true

echo \"Pulling new images...\"
docker pull \\\${DOCKER_IMAGE_FRONTEND}:\\\${BUILD_NUMBER}
docker pull \\\${DOCKER_IMAGE_BACKEND}:\\\${BUILD_NUMBER}

echo \"Creating docker-compose.yml if missing...\"
if [ ! -f docker-compose.yml ]; then
    cat > docker-compose.yml << \"COMPOSE\"
version: '3.8'
services:
  frontend:
    image: muqeem112/react-frontend:latest
    ports:
      - \"3000:3000\"
    depends_on:
      - backend
    environment:
      - REACT_APP_API_URL=http://20.205.24.111:5000

  backend:
    image: muqeem112/react-backend:latest
    ports:
      - \"5000:5000\"
    environment:
      - DB_HOST=mysql
      - DB_USER=root
      - DB_PASSWORD=password
      - DB_NAME=mernapp
    depends_on:
      - mysql

  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=password
      - MYSQL_DATABASE=mernapp
    ports:
      - \"3306:3306\"
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
COMPOSE
fi

echo \"Updating docker-compose.yml with new image tags...\"
sed -i \"s|image: \\\${DOCKER_IMAGE_FRONTEND}:.*|image: \\\${DOCKER_IMAGE_FRONTEND}:\\\${BUILD_NUMBER}|\" docker-compose.yml
sed -i \"s|image: \\\${DOCKER_IMAGE_BACKEND}:.*|image: \\\${DOCKER_IMAGE_BACKEND}:\\\${BUILD_NUMBER}|\" docker-compose.yml

echo \"Starting containers...\"
docker-compose up -d

echo \"Checking container status...\"
docker ps

echo \"=== Deployment completed for build: \\\$BUILD_NUMBER ===\"
ENDDEPLOY

                                chmod +x deploy.sh
                                echo "Running deployment script..."
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