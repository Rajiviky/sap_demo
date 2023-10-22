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
