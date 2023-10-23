host=$(kubectl get ingress -o jsonpath='{.items[0].spec.rules[0].host}')

# Construct the base URL by appending the host to the protocol
base_url="http://$host"

read -p "Enter the 'id': " id
read -p "Enter the 'message': " message

input_url="$base_url/inputJason?id=$id&message=$message"
output_url="$base_url/outputJason"

input_response=$(curl -s "$input_url")
output_response=$(curl -s "$output_url")

echo "HTTP responses from inputapp"
echo "Response from $input_url:"
echo "$input_response"

echo "Response from $output_url:"
echo "$output_response"