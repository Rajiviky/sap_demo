package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"
)

type JsonResponse struct {
	Id      int    `json:"id"`
	Message string `json:"message"`
}

var JsonInput []byte

func inputJson(w http.ResponseWriter, r *http.Request) {
	id_s := r.URL.Query().Get("id")
	message := r.URL.Query().Get("message")

	if id_s == "" || message == "" {
		w.Write([]byte("Error: 'message' and 'id' should not be empty"))
		return
	}
	id, err := strconv.Atoi(id_s)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	response := JsonResponse{Id: id, Message: message}

	JsonInput, err = json.Marshal(response)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(JsonInput)
}

func outputJson(w http.ResponseWriter, r *http.Request) {

	fmt.Println("jsonInput:", string(JsonInput))

	reverRes, err := reverseRedir(JsonInput)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Println("reverRes:", string(reverRes))

	w.Write(reverRes)
}

func reverseRedir(JsonInput []byte) ([]byte, error) {

	/* During k8s deployment serviceName := os.Getenv("SECOND_APP_SERVICE_NAME")
	url := "http://" + serviceName + ":5000/reverJson"  */

	// Read the URL from an environment variable
	host := os.Getenv("OUTPUTAPP_HOST")
	url := "http://" + host + "/reverJson"

	fmt.Println("reverseRedir:", string(JsonInput))
	fmt.Println("OUTPUTAPP_HOST", host)
	fmt.Println("connecting to app2")
	//url := "http://app2:5000/reverJson"

	reqBody := bytes.NewBuffer(JsonInput)

	resp, err := http.Post(url, "application/json", reqBody)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	fmt.Println("connecting to app2", url)

	if resp.StatusCode != http.StatusOK {
		return nil, err
	}

	outputJson, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	fmt.Println("outputJson:", string(outputJson))

	return outputJson, nil
}

func main() {

	mux := http.NewServeMux()

	mux.HandleFunc("/inputJson", inputJson)
	mux.HandleFunc("/outputJson", outputJson)

	http.ListenAndServe(":3000", mux)
}
