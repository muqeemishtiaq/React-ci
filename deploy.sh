#!/bin/bash

BUILD_NUMBER=$1
DOCKER_IMAGE_FRONTEND="muqeem112/react-frontend"
DOCKER_IMAGE_BACKEND="muqeem112/react-backend"

echo "Stopping existing containers..."
docker-compose down || true

echo "Removing old images..."
docker rmi ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} || true
docker rmi ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} || true

echo "Pulling new images..."
docker pull ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}
docker pull ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}

echo "Updating docker-compose.yml with new image tags..."
sed -i "s/image: ${DOCKER_IMAGE_FRONTEND}:.*/image: ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}/" docker-compose.yml
sed -i "s/image: ${DOCKER_IMAGE_BACKEND}:.*/image: ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}/" docker-compose.yml

echo "Starting containers..."
docker-compose up -d

echo "Checking container status..."
docker ps

echo "Deployment completed for build: ${BUILD_NUMBER}"

# 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