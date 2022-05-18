package main

import (
	"log"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"

	"github.com/govargo/gcp-manifests/activities"
	"github.com/govargo/gcp-manifests/workflows"
)

func main() {
	// The client and worker are heavyweight objects that should be created once per process.
	c, err := client.NewClient(client.Options{})
	if err != nil {
		log.Fatalln("Unable to create client", err)
	}
	defer c.Close()

	w := worker.New(c, "createCluster", worker.Options{})

	w.RegisterWorkflow(workflows.CreateClustersWorkflow)
	w.RegisterActivity(activities.Activity)

	err = w.Run(worker.InterruptCh())
	if err != nil {
		log.Fatalln("Unable to start worker", err)
	}
}
