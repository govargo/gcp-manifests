package workflows

import (
	"time"

	"go.temporal.io/sdk/workflow"

	"github.com/govargo/gcp-manifests/activities"
)

// Workflow is a Create GKE Clusters workflow definition.
func CreateClustersWorkflow(ctx workflow.Context, name string) (string, error) {
	ao := workflow.ActivityOptions{
		StartToCloseTimeout: 10 * time.Second,
	}
	ctx = workflow.WithActivityOptions(ctx, ao)

	logger := workflow.GetLogger(ctx)
	logger.Info("Create Clusters workflow started", "name", name)

	var result string
	err := workflow.ExecuteActivity(ctx, activities.Activity, name).Get(ctx, &result)
	if err != nil {
		logger.Error("Activity failed.", "Error", err)
		return "", err
	}

	logger.Info("Create Clusters workflow completed.", "result", result)

	return result, nil
}
