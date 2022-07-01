package workflows

import (
	"time"
	"log"

	"go.temporal.io/sdk/workflow"

	"github.com/govargo/gcp-manifests/activities"
)

// Workflow is a Create Global Resources workflow definition.
func CreateGlobalResourcesWorkflow(ctx workflow.Context, name string) (string, error) {
	ao := workflow.ActivityOptions{
		StartToCloseTimeout: 10 * time.Minute,
	}
	ctx = workflow.WithActivityOptions(ctx, ao)

	log.Printf("CreateGlobalResources workflow started: %s", name)

	var result string
	err := workflow.ExecuteActivity(ctx, activities.CreateGlobalResources, name).Get(ctx, &result)
	if err != nil {
		log.Fatalf("Activity CreateGlobalResources failed: %v", err)
		return "", err
	}

	log.Printf("Workflow result: %s", result)

	return result, nil
}
