package workflows

import (
	"time"
	"log"

	"go.temporal.io/sdk/workflow"

	"github.com/govargo/gcp-manifests/activities"
)

// Workflow is a Create GKE Clusters workflow definition.
func CreateClustersWorkflow(ctx workflow.Context, name string) (string, error) {
	ao := workflow.ActivityOptions{
		StartToCloseTimeout: 10 * time.Minute,
	}
	ctx = workflow.WithActivityOptions(ctx, ao)

	log.Printf("CreateGKEClusters workflow started: %s", name)

	cwo := workflow.ChildWorkflowOptions{
		WorkflowID: "CreateGlobalResouce",
	}
	ctx = workflow.WithChildOptions(ctx, cwo)

	var result string
	// Start creating Global Resources
	err := workflow.ExecuteChildWorkflow(ctx, CreateGlobalResourcesWorkflow, "CreateGlobalResourcesWorkflow").Get(ctx, &result)
	if err != nil {
		log.Fatalf("Received global resources creation failure: %v", err)
		return "", err
	}

	// Start creating Misc Clusters 
	err = workflow.ExecuteActivity(ctx, activities.CreateMiscCluster, name).Get(ctx, &result)
	if err != nil {
		log.Fatalf("Activity CreateMiscCluster failed: %v", err)
		return "", err
	}

	log.Printf("Workflow result: %s", result)

	return result, nil
}
