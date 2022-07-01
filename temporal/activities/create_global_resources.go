package activities

import (
	"context"
	"log"

	"github.com/hashicorp/terraform-exec/tfexec"
)

func CreateGlobalResources(ctx context.Context, name string) (string, error) {
	log.Printf("Activity name: %s", name)

	workingDir := "../terraform/global"
	tf, err := tfexec.NewTerraform(workingDir, "/usr/bin/terraform")
	if err != nil {
		log.Fatalf("error running NewTerraform ", "Error", err)
	}
	log.Print("terraform init to global")
	err = tf.Init(context.Background(), tfexec.Upgrade(true))
	if err != nil {
		log.Fatalf("error running Init", "Error", err)
	}

	return "Complete " + name + "!", nil
}
