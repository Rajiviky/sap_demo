#!/bin/bash

# Function to check if a Docker image tag already exists on Docker Hub
tag_exists_on_dockerhub() {
  local image="$1"
  local tag="$2"
  local exists=$(docker pull "$image:$tag" 2>&1 | grep -c "Image is up to date")
  if [ "$exists" -eq 1 ]; then
    return 0
  else
    return 1
  fi
}

# Function to validate the image tag format
is_valid_tag() {
  local tag="$1"
  # The tag should match the pattern: version-app_name (e.g., 1.1.0-inputapp)
  if [[ ! "$tag" =~ ^(inputapp|outputapp)-[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 1
  fi
  return 0
}

# Function to build and push the Docker image
build_and_push_image() {
  local docker_repo="$1"
  local tag="$2"
  local app_directory="$3"

  echo "Building Docker image $tag for $app_name from $app_directory..."
  docker build -t "$docker_repo:$tag" "$app_directory" && \
  echo "Pushing Docker image to Docker Hub..." && \
  docker push "$docker_repo:$tag" && \
  echo "Finished pushing image to $docker_repo"
}

# Function to deploy the Helm chart
deploy_helm_chart() {
  local app_name="$1"

  # Check if the release already exists
  release_exists=$(helm list -q -n default | grep "$app_name")

  if [ -z "$release_exists" ]; then
    echo "Installing Helm configuration for $app_name..."
    helm install -f helm/$app_name/values.yaml $app_name helm/$app_name
  else
    echo "Upgrading Helm configuration for $app_name..."
    helm upgrade -f helm/$app_name/values.yaml $app_name helm/$app_name
  fi
}

# Main script
docker_repo="rajimcy/codingchallenge-si"

while true; do
  # Prompt the user for a valid tag
  read -p "Enter the tag (e.g., inputapp-1.1.0 or outputapp-1.1.0): " tag

  if is_valid_tag "$tag"; then
    if tag_exists_on_dockerhub "$docker_repo" "$tag"; then
      echo "Image with tag $tag already exists on Docker Hub. Please choose a different tag."
    else
      break
    fi
  else
    echo "Invalid tag format. Example format: inputapp-1.1.0 or outputapp-1.1.0"
  fi
done

while true; do
  # Prompt the user for a commit message
  read -p "Enter a commit message: " commit_message

  # Commit and push the changes
  git add . && \
  git commit -m "$commit_message" && \
  git tag "$tag" && \
  git push origin "$tag" && \
  echo "Tagged and pushed successfully!"

  app_name=$(echo "$tag" | cut -d '-' -f 2)
  app_version=$(echo "$tag" | cut -d '-' -f 1)

  # Choose the directory based on app_name
  if [ "$app_name" == "inputapp" ]; then
    app_directory="./inputapp"
  elif [ "$app_name" == "outputapp" ]; then
    app_directory="./outputapp"
  else
    echo "Invalid app name in the image tag. Use 'X.Y.Z-inputapp' or 'X.Y.Z-outputapp' format."
    exit 1
  fi

  # Build and push the Docker image
  build_and_push_image "$docker_repo" "$tag" "$app_directory"

  # Deploy the Helm chart
  deploy_helm_chart "$app_name"

  # Ask the user if they want to build and deploy another application or tag
  read -p "Do you want to build and deploy another application or tag? (yes/no): " continue
  if [ "$continue" != "yes" ]; then
    break
  fi

  while true; do
    # Prompt the user for a valid tag
    read -p "Enter the tag (e.g., inputapp-1.1.0 or outputapp-1.1.0): " tag

    if is_valid_tag "$tag"; then
      if tag_exists_on_dockerhub "$docker_repo" "$tag"; then
        echo "Image with tag $tag already exists on Docker Hub. Please choose a different tag."
      else
        break
      fi
    else
      echo "Invalid tag format. Example format: inputapp-1.1.0 or outputapp-1.1.0"
    fi
  done
done

# Proceed with the final steps
read -p "Enter the 'id': " id
read -p "Enter the 'message': " message

base_url="http://demoinputapp.info"

input_url="$base_url/inputJason?id=$id&message=$message"
output_url="$base_url/outputJason"

input_response=$(curl -s "$input_url")
output_response=$(curl -s "$output_url")

echo "HTTP responses from inputapp"

echo "Response from $input_url:"
echo "$input_response"

echo "Response from $output_url:"
echo "$output_response"
