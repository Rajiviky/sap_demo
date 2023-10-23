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
  if [[ ! "$tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+-(inputapp|outputapp)$ ]]; then
    return 1
  fi
  return 0
}


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

# Prompt the user for a commit message
read -p "Enter a commit message: " commit_message

# Commit and push the changes
git add .
git commit -m "$commit_message"
git tag "$tag"
git push origin "$tag"
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

# Build the Docker image from the chosen directory
echo "Building Docker image for $app_name from $app_directory..."
docker build -t "$docker_repo:$tag" "$app_directory"

# Push the image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push "$docker_repo:$tag"
echo "Tagged and pushed successfully!"
