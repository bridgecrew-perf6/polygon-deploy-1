## Description
In this document we will describe how to deploy Polygon nodes onto Google Kubernetes Engine clusters

## Hardware requirements
Check minimum and recommended [hardware requirements](https://docs.polygon.technology/docs/validate/mainnet/validator-guide) in Polygon docs

## Software requirements for deployment
1. Linux terminal (or you can run through this via `CloudShell`. Currently, it's debian10 and x86_64 architecture )
2. [`gcloud`](https://cloud.google.com/sdk/docs/install)(Already installed in `CloudShell`)
3. [`kubectl`](https://v1-20.docs.kubernetes.io/docs/tasks/tools/included/install-kubectl-gcloud/)(Already installed in `CloudShell`)
4. [`sops`](https://github.com/mozilla/sops/releases) 
5. [`helm`](https://helm.sh/docs/intro/install/)
6. [`helm-secrets`](https://github.com/jkroepke/helm-secrets/wiki/Installation)
7. [`helmfile`](https://github.com/roboll/helmfile#installation)
    to install `Helmfile` in `CloudShell` just run this little script:
    ```
    wget https://github.com/roboll/helmfile/releases/download/v0.143.0/helmfile_linux_amd64 -O helmfile 
    chmod +x helmfile
    sudo mv helmfile /usr/local/bin/helmfile
    ```

# Solution Deploy

## Step 1: Deploy infra via terragrunt
0. Open `cloud shell` in your destination GCP project and run command to retrieve your projectID:
```
export project_id=`gcloud config get-value project`
export TF_VAR_project_id=$project_id
```
1. Setup all requirements from `Software requirements for deployment` chapter of the doc.
2. Network plan could be reused, in case you wish to deploy in 3 or less AvailabilityZones
3. In directory `terragrunt` run command `terrgrunt apply-all` and confirm the changes.

## Step 2: Deploy the Application via helmfile
### Pre-liminary steps
1. From step one you have created a couple GKE clusters up and running. It's time to connect to them by running the \
    command `gcloud container clusters get-credentials CLUSTER_NAME --region CLUSTER_REGION --project PROJECT_ID`
2. On step 1 the KMS keyring was created. KMS is encryption service and we have some secrets to encrypt.
    - In case you switched to a new project: please, check paths in `app/.sops.yaml`
    - In case you switched to a new project: fill files `app/environments/ENV_NAME/secrets/rabbit.yaml` with new secrets (see `app/environments/asia/secrets/rabbit.yaml.sample`)
    - In case you switched to a new project: run `cd app && sops --encrypt environments/ENV_NAME/secrets/rabbit.yaml > environments/ENV_NAME/secrets/rabbit.yaml.enc`\
        for each Environment to encrypt your fresh secrets. Remove `rabbit.yaml` and rename `rabbit.yaml.enc` to `rabbit.yaml`
    - In case you switched to a new project: retrive external IPs per each zone from `terragrunt` and put it into `helmfile`:
      1. in each dir `terragrunt/envs/ENV_NAME/ips` run `terragrunt output addresses` 
      2. get the IP and replace external IPs in `app/environments/ENV_NAME/helmfile.yaml`
      3. there is a separate IP for Global Load Balancer. To get it run terragrunt output addresses` in `terragrunt/envs/glb`
      4. put GLB address into `app/environments/eu/helmfile.yaml` as value for `global_ip: ` parameter in `mci` release
      5. also, put your `kubectl` context for appropriate cluster in `app/environments/ENV_NAME/helmfile.yaml` as value for `context:`
3. It's time to run deployment of our nodes. In `app/environments/` run `helmfile sync`. \
    In case you wish to deploy zone-by-zone you can execute helmfile in same ditectory with additional key like `helmfile -e eu sync`
