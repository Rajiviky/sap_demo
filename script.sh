#!/bin/bash

# Function to check if a tag is in the right format (e.g., inputapp-1.1.0)
is_valid_tag() {
  if [[ "$1" =~ ^(inputapp|outputapp)-[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

# Prompt the user for a valid tag
read -p "Enter the tag (e.g., inputapp-1.1.0 or outputapp-1.1.0): " tag

if ! is_valid_tag "$tag"; then
  echo "Invalid tag format. Example format: inputapp-1.1.0 or outputapp-1.1.0"
  exit 1
fi

# Prompt the user for a commit message
read -p "Enter a commit message: " commit_message

# Tag the local branch without committing
git add .
git commit -m "$commit_message"
git tag "$tag"

# Push the tag to the remote
git push origin "$tag"

echo "Tagged and pushed successfully!"

# Check if the Docker image tag already exists on Docker Hub
docker_repo="rajimcy/codingchallenge-si"
if tag_exists_on_dockerhub "$docker_repo" "$tag"; then
  echo "Image with tag $tag already exists on Docker Hub. Aborting."
  exit 1
fi

# Split the image tag into app_name and app_version
app_name=$(echo "$tag" | cut -d '-' -f 1)
app_version=$(echo "$tag" | cut -d '-' -f 2)

# Choose the directory based on app_name
if [ "$app_name" == "inputapp" ]; then
  app_directory="./inputapp"
elif [ "$app_name" == "outputapp" ]; then
  app_directory="./outputapp"
else
  echo "Invalid app name in the image tag. Use 'inputapp-versionnumber' or 'outputapp-versionnumber'."
  exit 1
fi

# Build the Docker image from the chosen directory
echo "Building Docker image for $app_name from $app_directory..."
docker build -t "$docker_repo:$tag" "$app_directory"



# Push the image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push "$docker_repo:$tag"



echo "Tagged and pushed successfully!"