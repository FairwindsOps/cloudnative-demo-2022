# CloudNative 2022 Demo

This is a demo for the DevOps/Cloud-Native and Cybersecurity conferences in Boston, 5/25-26

# Instructions
## Prerequisites
* Docker: https://docs.docker.com/engine/install/
* kubectl: https://kubernetes.io/docs/tasks/tools/#kubectl
* Helm: https://helm.sh/docs/intro/install/
* KIND: https://kind.sigs.k8s.io/docs/user/quick-start/
* insights-cli: https://github.com/FairwindsOps/insights-cli/releases/tag/v1.0.0

## Set up Fairwinds Insights
To start, sign into Fairwinds Insights at https://insights.fairwinds.com - you'll be
provided with an email address and password.

Find your admin token at https://insights.fairwinds.com/orgs/cloudnative-demo-2022/settings/tokens
and run
```bash
export FAIWINDS_TOKEN=yIrUK[REDACTED]VhYDX
```
to set it in your environment.

## Build a Policy
We have a pre-built policy for requiring a `costCenterCode` label here in the `opa/required-label/`
directory. To get started with your own policy, run
```bash
mv opa/required-label opa/your-name
```
`your-name` should be replaced by a unique string you'll remember (lowercase letters and `-` only)

Now you can edit your OPA policy. At the very least, change the `title` to something unique, so your
policy doesn't get confused with anyone else's. You can also change the string `costCenterCode` to something
else, or try changing the policy entirely!

### Test your Policy
Once you're happy with your policy, it's time to test it!

Change `opa/your-name/test/deployment.success.yaml` to something that should pass your policy, and change
`opa/your-name/deployment.failure.yaml` to something that should fail. Then you can run:

```bash
insights-cli validate opa \
  --rego-file opa/required-label/policy.rego \
  --kube-object-file opa/required-label/test/deployment.failure.yaml

# Action Item:
#    Title: costCenterCode label is required
#    Category: Reliability
#    ...
```

```bash
insights-cli validate opa \
  --rego-file opa/required-label/policy.rego \
  --kube-object-file opa/required-label/test/deployment.success.yaml

# OPA policy failed validation: 0 action items were returned, but 1 is required
```

### Sync your Policy
Once your tests are passing properly, it's time to sync your policy to Insights.

```bash
insights-cli push opa
```

Visit [the Policy page](https://insights.fairwinds.com/orgs/cloudnative-demo-2022/policy/) in Insights
and make sure you see your name there.

## Scan your Cluster for violations
First, let's create some files to deploy to the cluster. We can re-use the files we were using to
test our policy.
```bash
cp opa/your-name/test/* deploy/
git add .
git commit -a -m "Create deployment files"
```

Next, let's create a KIND cluster to deploy them to:
```bash
kind create cluster --image kindest/node:v1.22.0@sha256:b8bda84bb3a190e6e028b1760d277454a72267a5454b57db34437c34a588d047
```

And let's add them to the cluster:
```bash
kubectl create ns your-name
kubectl apply -f deploy/ -n YOURNAME
```

Next, we have to add a new Kubernetes Cluster to Fairwinds Insights:
* Visit https://insights.fairwinds.com/orgs/cloudnative-demo-2022/clusters
* Click "Add Cluster" in the top right
* Give the cluster a unique name
* Find the "Open Policy Agent" report and click "Quick Add"
* Click "Ready to install" at the top of the page
* Copy the values.yaml files
* Add the following to get the latest OPA features
```
opa:
  enabled: true
  image:
    tag: 2.0
```
* Run the `helm upgrade` command

Once your `helm` command completes, you can see the new Action Items by visiting
https://insights.fairwinds.com/orgs/cloudnative-demo-2022/action-items/
and selecting your cluster.

## Setting up the Admission Controller
### Install cert-manager
The admission contoller requires an SSL certificate to work. So we'll need to install cert-manager
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
```

### Install the Admission Controller
Next we need to install the admission controller itself:
* Visit https://insights.fairwinds.com/orgs/cloudnative-demo-2022/clusters/
* Choose your cluster
* Click "Install Hub"
* Add the "Admission Controller"
* Click into the card
* Under Blocking Reports uncheck Polaris
* Turn off Passive Mode
* Navigate back to the Hub
* Click "Ready to Reinstall" at the top
* Copy values.yaml again
* Add the following to your values.yaml to get the latest admission controller features
```yaml
insights-admission:
  image:
    tag: "1.3"
```
* Re-run the `helm install` command

### Try to deploy
Now we can trigger the admission controller. Run:
```bash
kubectl delete -f deploy/ -n your-name
kubectl apply -f deploy/ -n your-name
```

You should see an error message that your deployment was blocked.

You can see this block event in the UI by visiting
https://insights.fairwinds.com/orgs/cloudnative-demo-2022/clusters/
and choosing your cluster, then going to the `Admission Controller` tab.

## Run in CI/CD
Now let's run our policy against Infrastructure-as-Code, like we would in a CI/CD process.

In `fairwinds-insights.yaml`, change `repositoryName` to your name so that you don't overwrite
anyone else's results.

Next run these commands to run the CI script:
```bash
curl -L https://insights.fairwinds.com/v0/insights-ci-1.0.0.sh > insights-ci.sh
echo "8c193c8a333c269ed3fa50ded4bab91394f0344af531488f80a089fbcbea45b8 *insights-ci.sh" | shasum -a 256 --check
chmod +x insights-ci.sh
./insights-ci.sh
```

You should see an action item for your deployment file. You can see your repo in the UI at
https://insights.fairwinds.com/orgs/cloudnative-demo-2022/repositories
