package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"

	"github.com/Rajiviky/sap_demo/tree/raji/structcommon"
)

var JsonInput []byte

func inputJason(w http.ResponseWriter, r *http.Request) {
	id_s := r.URL.Query().Get("id")
	message := r.URL.Query().Get("message")

	// Error handling: Write error code (400), if either "id" or "message" is missing.(enhnace it later)
	if id_s == "" || message == "" {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	id, err := strconv.Atoi(id_s)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	response := structcommon.JsonResponse{Id: id, Message: message}

	JsonInput, err = json.Marshal(response)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(JsonInput)
}

func outputJason(w http.ResponseWriter, r *http.Request) {

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

	url := "http://localhost:5000/reverJson"

	fmt.Println("reverseRedir:", string(JsonInput))

	reqBody := bytes.NewBuffer(JsonInput)

	resp, err := http.Post(url, "application/json", reqBody)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, err
	}

	outputJason, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	fmt.Println("outputJason:", string(outputJason))

	return outputJason, nil
}

func main() {

	mux := http.NewServeMux()

	mux.HandleFunc("/inputJason", inputJason)
	mux.HandleFunc("/outputJason", outputJason)

	http.ListenAndServe(":3000", mux)
}
