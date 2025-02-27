# Terraform module

## Preparation

1. Need to change the project id and name for your owns
2. And need to create GCS bucket for terraform tfstate(e.g. <PROJECT_ID>-terraform-bucket)
3. Enable cloudresourcemanager.googleapis.com iam.googleapis.com API, because terraform requires this
4. Activate Security Command Center Standard(Free) via Cloud Console UI
5. Create OAuth client Credential(Web) for ArgoCD via Cloud Console UI
6. Add IAMBinding roles/storage.admin to yourself

## Apply order

1. global ※ after apply, enable billing export to BigQuery, add secret values
2. network
3. spanner
4. cloudsql
5. memorystore
6. firebase
7. scc
8. logging 
9. monitoring
10. bigquery
11. pubsub
12. dataform
13. datastream
14. armor
15. gke ※ comment-out backend-service for argocd
16. gkefleet
17. run
18. functions
19. workflow
20. dataplex

### Other

(Visualize your costs with Looker Studio)[https://cloud.google.com/billing/docs/how-to/visualize-data] can be created, after billing export data is exported.