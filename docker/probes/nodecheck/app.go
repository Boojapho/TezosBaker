package main

import (
    "encoding/json"
    "fmt"
    "io/ioutil"
    "log"
    "net/http"
    "os"
    "strconv"
    "time"
)

type Header struct {
	Level int
}

/* This program is inteneded to be used as a liveness check for a Tezos node
 * It will connect to the RPC at localhost:8732
 * The node is considered healthy if the number of peers > 1 and
 * the block level has progressed since the last check
 * The last block level is stored in $data_dir/last_block
 * If the peer check passes, but the block hasn't progressed, a "resync" file
 * is created in the $data_dir.  This can be used by an init container to
 * re-create the node from a snapshot or other means of fixing the node problem.
 */

func main() {
	check_peers()
	check_header()
}

// If error is passed in, exits program with exit code 1
func checkError(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

// Grab body from URL
func getBody(url string) []byte {

	// Make sure we don't hang
	thisClient := http.Client {
		Timeout: time.Second * 10,
	}

	res, err := thisClient.Get(url)
	checkError(err)

	if res.Body != nil {
		defer res.Body.Close()
	}
	if res.StatusCode != http.StatusOK {
		log.Fatal(url, " - Status Code != OK")
	}

	// Read the body
	body, err := ioutil.ReadAll(res.Body)
	checkError(err)

	return body
}

// Make sure block level has progressed
func check_header() {
	url := "http://localhost:8732/chains/main/blocks/head/header"
	data_dir := "/home/tezos/.tezos-node"
	last_block := data_dir + "/last_block"
	resync := data_dir + "/resync"
	body := getBody(url)

	// Parse the JSON
	var header Header
	err := json.Unmarshal(body, &header)
	checkError(err)

	// Get last block
	data, err := ioutil.ReadFile(last_block)
	if err == nil {
		if string(data) == strconv.Itoa(header.Level) {
			err = ioutil.WriteFile(resync, []byte(""), 0644)
			checkError(err)
			log.Fatal("Block level has not changed!")
		} else {
			os.Remove(resync)
		}
	}

	// Write last block state
	err = ioutil.WriteFile(last_block, []byte(strconv.Itoa(header.Level)), 0644)
	checkError(err)
	fmt.Println("Current block level is now", header.Level)
}

// Checks to make sure number of peers is > 1
func check_peers() {
	url := "http://localhost:8732/network/connections"
	body := getBody(url)

	// Parse the JSON
	var jsonObjs interface{}
	err := json.Unmarshal(body, &jsonObjs)
	checkError(err)

	// Split the JSON into peers
	objSlice, sliceErr := jsonObjs.([]interface{})
	if !sliceErr {
		log.Fatal("Connot convert the JSON objects")
	}

	// Count the objects
	if len(objSlice) > 1 {
		fmt.Println("Peer count of", len(objSlice), "is ok.")
	} else {
		log.Fatal("Peer count is too low!")
	}
}
