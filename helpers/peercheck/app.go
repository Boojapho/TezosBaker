package main

import (
    "encoding/json"
    "fmt"
    "io/ioutil"
    "log"
    "net/http"
    "time"
)

/* This program is inteneded to be used as a liveness check for a Tezos node
 * It will connect to the node at localhost:8732 and query the connections
 * It then parses the output to count the number of peers connected
 * The program will exit with an error unless the number of peers > 1
 */
func main() {
	url := "http://localhost:8732/network/connections"

	// Make sure we don't hang
	thisClient := http.Client {
		Timeout: time.Second * 10,
	}

	res, err := thisClient.Get(url)
	if err != nil {
		log.Fatal(err)
	}

	if res.Body != nil {
		defer res.Body.Close()
	}

	if res.StatusCode == http.StatusOK {
		// Read the body
		body, err := ioutil.ReadAll(res.Body)
		if err != nil {
			log.Fatal(err)
		}

		// Parse the JSON
		var jsonObjs interface{}
		jsonErr := json.Unmarshal(body, &jsonObjs)
		if jsonErr != nil {
			log.Fatal(jsonErr)
		}

		// Split the JSON into peers
		objSlice, sliceErr := jsonObjs.([]interface{})
		if !sliceErr {
			log.Fatal("Connot convert the JSON objects")
		}

		// Count the objects
		if len(objSlice) > 1 {
			fmt.Println("Peer count of", len(objSlice), "is ok.")
		} else {
			log.Fatal("Peer count of", len(objSlice), "is too low!")
		}
	} else {
		log.Fatal("Status Code != OK")
	}
}
