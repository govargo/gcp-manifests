package main

import (
	"context"
	"log"

	"github.com/google/uuid"
	"go.temporal.io/sdk/client"

	"github.com/govargo/gcp-manifests/workflows"
)

func main() {
	// The client is a heavyweight object that should be created once per process.
	c, err := client.NewClient(client.Options{})
	if err != nil {
		log.Fatalln("Unable to create client", err)
	}
	defer c.Close()

	workflowUUID, err := uuid.NewUUID()
	workflowOptions := client.StartWorkflowOptions{
		ID:        workflowUUID.String(),
		TaskQueue: "createCluster",
	}

	ctx := context.Background()
	we, err := c.ExecuteWorkflow(ctx, workflowOptions, workflows.CreateClustersWorkflow, "CreateCluster")
	if err != nil {
		log.Fatalln("Unable to execute workflow", err)
	}
	log.Println("Started CreateCluster workflow", "WorkflowID", we.GetID(), "RunID", we.GetRunID())

	// Synchronously wait for the workflow completion.
	var result string
	err = we.Get(context.Background(), &result)
	if err != nil {
		log.Fatalln("Unable get workflow result", err)
	}
	log.Println("Workflow result:", result)
}
