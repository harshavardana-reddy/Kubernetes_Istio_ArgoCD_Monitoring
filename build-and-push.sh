#!/bin/bash

# Set your Docker Hub username
DOCKER_USERNAME="harshareddy2024"

# Array of folders and their corresponding image names
declare -A services=(
    ["ADMIN_SERVICE"]="admin-service"
    ["API_GATEWAY"]="api-gateway"
    ["EUREKHA_SERVER"]="eureka-server"
    ["FACULTY_SERVICE"]="faculty-service"
    ["STUDENT_SERVICE"]="student-service"
)

echo "Starting build and push process for all services..."
echo "==================================================="

# Function to build and package a service
build_service() {
    local folder=$1
    local image_name=$2
    
    echo "Building $folder..."
    echo "------------------------"
    
    # Navigate to the service directory
    cd "$folder" || { echo "Error: Directory $folder not found!"; return 1; }
    
    # Run Maven clean package
    echo "Running mvn clean package -DskipTests for $folder..."
    mvn clean package -DskipTests
    
    if [ $? -eq 0 ]; then
        echo "Maven build successful for $folder"
        
        # Build Docker image
        echo "Building Docker image: $DOCKER_USERNAME/$image_name"
        docker build -t "$DOCKER_USERNAME/$image_name" .
        
        if [ $? -eq 0 ]; then
            echo "Docker build successful for $image_name"
        else
            echo "Error: Docker build failed for $image_name"
            cd ..
            return 1
        fi
        
    else
        echo "Error: Maven build failed for $folder"
        cd ..
        return 1
    fi
    
    # Return to parent directory
    cd ..
    echo ""
}

# Function to push a Docker image
push_image() {
    local image_name=$1
    
    echo "Pushing $DOCKER_USERNAME/$image_name..."
    echo "------------------------"
    
    # Push the Docker image
    docker push "$DOCKER_USERNAME/$image_name"
    
    if [ $? -eq 0 ]; then
        echo "Successfully pushed $DOCKER_USERNAME/$image_name"
    else
        echo "Error: Failed to push $DOCKER_USERNAME/$image_name"
        return 1
    fi
    
    echo ""
}

# Build all services
echo "PHASE 1: Building all services..."
echo "================================="
for folder in "${!services[@]}"; do
    build_service "$folder" "${services[$folder]}"
done

# Check if any build failed
if [ $? -ne 0 ]; then
    echo "Error: One or more builds failed. Aborting push process."
    exit 1
fi

# Push all images
echo "PHASE 2: Pushing all images to Docker Hub..."
echo "============================================"
for image_name in "${services[@]}"; do
    push_image "$image_name"
done

echo "==================================================="
echo "Build and push process completed!"
echo "All images have been built and pushed to Docker Hub: $DOCKER_USERNAME"
echo ""
echo "Available images:"
for image_name in "${services[@]}"; do
    echo "  - $DOCKER_USERNAME/$image_name"
done