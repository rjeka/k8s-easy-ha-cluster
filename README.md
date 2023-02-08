# Deploying a High Available Kubernetes Cluster


##The playbook deploys a highly available Kubernetes cluster by performing the following tasks:

- Creating a temporary directory (/tmp/k8s) to store certificates
- Installing kubelet, kubectl, and kubeadm on masters, workers, and ingress nodes
- Setting up CRI on all nodes
- Installing an ETCD cluster with TLS on master nodes
- Initializing the first master node using kubeadm and creating cluster certificates
- Adding remaining master nodes to the cluster
- Installing CNI for network configuration
- Adding worker nodes to the cluster
- Setting up HAProxy as API load balancer
- Configuring the ingress controller
- Setting up Helm for package management."


## Getting started:

```bash
git clone https://github.com/rjeka/k8s-easy-ha-cluster.git
cd k8s-easy-ha-cluster
vim hosts
```

```bash
ansible-playbook -i <inventory> install_kubernetes_cluster.yml
```



