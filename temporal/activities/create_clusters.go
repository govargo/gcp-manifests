package activities

import (
	"context"
	"log"

	"github.com/hashicorp/terraform-exec/tfexec"
)

func CreateMiscCluster(ctx context.Context, name string) (string, error) {
	log.Printf("Activity name: %s", name)

	workingDir := "../terraform/gke/misc"
	tf, err := tfexec.NewTerraform(workingDir, "/usr/bin/terraform")
	if err != nil {
		log.Fatalf("error running NewTerraform: %v", err)
	}
	log.Print("terraform init to misc")
	err = tf.Init(context.Background(), tfexec.Upgrade(true))
	if err != nil {
		log.Fatalf("error running Init: %v", err)
	}

	return "Complete " + name + "!", nil
}
