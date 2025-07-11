# Project Name  
End to End Splunk Cluster in AWS.  

## 🚀 Installation  
1. Start with deploying the network from the network directory
2. Next is to deploy the resources from mgmt directory which contains an app deployment workflow for splunk apps triggered from s3, nat gateway, bastion hosts and supporting iam and network resources
3. Finally deploy from splunk-cluster which is customizable to be single node or full fledged with SHC and Indexer clusters
4. All configs to pick cluster sizes can be applied from variables.tf in splunk-cluster

## 🎯 Usage  
All infra in terraform and setup scripts are in bash. 
Start by setting up terraform and aws access keys locally. 
Install aws cli
if deploying from local use the standard terraform flow. 
terraform init;terraform plan;terraform apply
Otherwise leverage a terraform CI-CD pipeline as https://developer.hashicorp.com/terraform/tutorials/automation/github-actions
