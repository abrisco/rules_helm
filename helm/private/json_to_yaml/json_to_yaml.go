package main

import (
	"encoding/json"
	"flag"
	"log"
	"os"

	"gopkg.in/yaml.v3"
)

func main() {
	input := flag.String("input", "", "The path to the json file to convert to yaml")
	output := flag.String("output", "", "The path where the generated yaml file should be written.")

	flag.Parse()

	content, err := os.ReadFile(*input)
	if err != nil {
		log.Fatal(err)
	}

	var json_obj interface{}
	err = json.Unmarshal(content, &json_obj)
	if err != nil {
		log.Fatal(err)
	}

	yaml_content, err := yaml.Marshal(&json_obj)
	if err != nil {
		log.Fatal(err)
	}

	err = os.WriteFile(*output, []byte(yaml_content), 0644)
	if err != nil {
		log.Fatal(err)
	}
}
