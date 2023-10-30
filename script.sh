#!/bin/bash

# Function to check for unique docker image tag
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

# Function to validate the tag format
is_valid_tag() {
  local tag="$1"
  if [[ ! "$tag" =~ ^(inputapp|outputapp)-[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 1
  fi
  return 0
}

# Function to build and push the tag
build_and_push_image() {
  local docker_repo="$1"
  local tag="$2"
  local app_directory="$3"
  echo "..............................................................................."
  echo "Building Docker image $tag for $app_name from $app_directory..."
  echo "..............................................................................."
  docker build -t "$docker_repo:$tag" "$app_directory" > /dev/null 2>&1 && \
  echo "Pushing Docker image to Docker Hub..." && \
  docker push "$docker_repo:$tag" > /dev/null 2>&1 && \
  echo "..............................................................................."
  echo "Finished pushing image to $docker_repo"
  echo "..............................................................................."

}

# Function to deploy the Helm chart
deploy_helm_chart() {
  local app_name="$1"

  release_exists=$(helm list -q -n default | grep "$app_name")

  if [ -z "$release_exists" ]; then
    echo "..............................................................................."
    echo "Installing Helm configuration for $app_name..."
    helm install -f helm/$app_name/values.yaml $app_name helm/$app_name
    echo "..............................................................................."
  else
    echo "..............................................................................."
    echo "Upgrading Helm configuration for $app_name..."
    helm upgrade -f helm/$app_name/values.yaml $app_name helm/$app_name
    echo "..............................................................................."
  fi
}

docker_repo="rajimcy/codingchallenge-si"

while true; do
  # Prompt the user for a valid tag
  read -p "Enter the tag (e.g., inputapp-1.1.0 or outputapp-1.1.0): " tag

  if is_valid_tag "$tag"; then
    if tag_exists_on_dockerhub "$docker_repo" "$tag"; then
      echo "Image with tag $tag already exists on Docker Hub. Please choose a unique tag."
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

  app_name=$(echo "$tag" | cut -d '-' -f 1)
  app_version=$(echo "$tag" | cut -d '-' -f 2)

  # Commit and push the changes
  git add ./$app_name && \
  git commit -m "$commit_message" && \
  git tag "$tag" && \
  git push origin "$tag" && \
  echo "changes Tagged and pushed successfully!"

  echo "..............................................................................."
  
  # Choose the directory based on app_name
  if [ "$app_name" == "inputapp" ]; then
    app_directory="./inputapp"
  elif [ "$app_name" == "outputapp" ]; then
    app_directory="./outputapp"
  else
    echo "Invalid app name in the image tag. Use 'inputapp-1.1.0 or outputapp-1.1.0' format."
    exit 1
  fi

  # Build and push the Docker image
  build_and_push_image "$docker_repo" "$tag" "$app_directory"

  read -p "Proceed with deploying the Helm chart for $app_name? (yes/no): " deploy_confirmation
    if [ "$deploy_confirmation" != "yes" ]; then
      echo "skipped deployment and exiting...."
       exit 0
    fi

  # Deploy the Helm chart
  deploy_helm_chart "$app_name"

  # Prompt the user if they want to build and deploy another application or tag
  read -p "Do you want to build and deploy another application or tag? (yes/no): " continue
  if [ "$continue" != "yes" ]; then
    break
  fi

  while true; do
    # Prompt the user for a valid tag
    read -p "Enter the tag (e.g., inputapp-1.1.0 or outputapp-1.1.0): " tag
     echo "New tag:"$tag
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
 # Retrieve the host from the Ingress using kubectl
host=$(kubectl get ingress -o jsonpath='{.items[0].spec.rules[0].host}')

# Construct the base URL by appending the host to the protocol
base_url="http://$host"
echo "..............................................................................."

read -p "Enter the 'id': " id
read -p "Enter the 'message': " message

input_url="$base_url/inputJson?id=$id&message=$message"
output_url="$base_url/outputJson"

input_response=$(curl -s "$input_url")
output_response=$(curl -s "$output_url")
echo "..............................................................................."
echo "HTTP responses from inputapp"
echo "Response from $input_url:"
echo "$input_response"

echo "Response from $output_url:"
echo "$output_response"