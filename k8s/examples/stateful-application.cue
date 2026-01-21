package examples

import "github.com/emillamm/cuefig/k8s"

_k8s: k8s & {
	#Name:             "myservice"
	#Project:          "myproject"
	#Region:           "us-east1"
	#ContainerVersion: "0.0.0-xyz"

	deployment: #GSA: "google-service-account@myproject.iam.gserviceaccount.com"
	rollout: _k8s.rolloutconfiguration.stateful
	//rollout: #InitContainers: [_k8s.spanner.#Sidecar]
	//rollout: #Env: list.Concat([_k8s.#CommonEnv, _k8s.spanner.#Env])
}

//ns: _k8s.#Namespace
//job: _k8s.spanner.#MigrationJob & {}
//service:    _k8s.rollout.#Service
rollout:    _k8s.rollout.#Rollout
deployment: _k8s.deployment.#Deployment
//sa:         _k8s.deployment.#ServiceAccount
