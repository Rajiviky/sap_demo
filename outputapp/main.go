package main

import (
	"encoding/json"
	"net/http"

	"github.com/Rajiviky/sap_demo/tree/raji/structcommon"
)

func revMsg(input string) string {
	runes := []rune(input)
	reversed := make([]rune, len(runes))
	for i, j := 0, len(runes)-1; i < len(runes); i, j = i+1, j-1 {
		reversed[i] = runes[j]
	}
	return string(reversed)
}

func reverseJson(w http.ResponseWriter, r *http.Request) {
	var req structcommon.JsonResponse

	JsonDec := json.NewDecoder(r.Body)
	if err := JsonDec.Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)S
		return
	}

	revMsg := revMsg(req.Message)
	revRes := structcommon.JsonResponse{
		ID:      req.ID,
		Message: revMsg,
	}

	resJson, err := json.Marshal(revRes)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(resJson)
}

func main() {
	mux := http.NewServeMux()

	mux.HandleFunc("/reverJson", reverseJson)

	http.ListenAndServe(":5000", mux)
}
