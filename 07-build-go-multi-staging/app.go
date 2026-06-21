package main

import (
	"fmt"
	"net/http"
	"os"
)

func handler(w http.ResponseWriter, r *http.Request) {
	var name, _ = os.Hostname()

	fmt.Fprintf(w, "<h1> This request was processed by host:%s </h1>", name)
}

func main() {
	fmt.Fprintf(os.Stdout, "Starting server on port 3000...\n")

	http.HandleFunc("/", handler)
	http.ListenAndServe(":3000", nil)
}
