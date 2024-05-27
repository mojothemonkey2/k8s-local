# k8s-local - Local Kubernetes Environements for Windows

Guide for setting up local Kubernetes clusters on your Windows Desktop, specifically for use with Linux Foundation courses:
* [LFS158 - Introduction to Kubernetes](https://training.linuxfoundation.org/training/introduction-to-kubernetes/)
* [LFS258 - Kubernetes Fundamentals](https://training.linuxfoundation.org/training/kubernetes-fundamentals/)

---
## Requirements
* Windows 10/11 Pro (or Enterprise).
* 16GB RAM.

You should not need much CPU. I ran my clusters on a NUC with N6005 quad-core cpu.

## Hyper-V
For both setups, I shall use Hyper-V as the backend. This is the preferred driver. \
Docker driver on WSL2 proved to be a bit flakey. \
VirtualBox is another option, if you have Windows Home. Supported by both Minikube and Multipass, though I could not figure out how to add a second, static interface using Multipass.

Hyper-V can be enabled with:
```
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```
And a reboot.

You can open "Hyper-V Manager" console to keep an eye on VMs.

---
## Minikube
This is the tool used to create pre-configured clusters in the Introduction to Kuberentes labs.

Refs:
* Install https://minikube.sigs.k8s.io/docs/start/
* Usage https://minikube.sigs.k8s.io/docs/commands/

Quick-start (admin terminal):
```
minikube config set driver hyperv                            #set hyperv as default driver
minikube start --nodes=2 --addons=metrics-server,ingress     #fire up cluster of 2 nodes
minikube dashboard                                           #open the dashboard
```

---
## Multipass
For the Kubernetes Fundamentals labs, we need to install Kuberentes clusters from scratch, using kubeadm. \
They propose using cloud instances, but this would soon run up costs. \
Instead, we can use [Multipass](https://multipass.run/) to launch cloud images locally.

Benefits:
* Easy CLI usage.
* Cloud images - with minimal resource usage.
* Supports [cloud-init](https://cloudinit.readthedocs.io/en/latest/) configuration, that we can use to pre-configure our instances as desired. \
  But with some limitations:
  - No network-config.
  - No templating.
  
  (we can work around these with a little hacking in our cloud-init config).

### Install
https://multipass.run/docs/installing-on-windows

### Quick Ref
```
multipass find               #list distros
multipass list               #list vms, with IPs/dist

multipass start lfclass-cp   #start vm
multipass stop lfclass-cp    #shutdown vm
multipass shell lfclass-cp   #open a bash shell

multipass delete lfclass-cp  #delete a vm
multipass purge              #need to purge deleted vms to remove them from multipass

multipass set local.lfclass-cp.disk=20G  #mod vm config
```

### Network Setup
Multipass requires the primary interface to be on the default Hyper-V switch, which is fixed to DHCP. \
But an IP change will break Kubernetes setup. So to avoid this, we will configure a second, static interface for each node.

The Fundamentals course specifies a single network interface, for simplicity. \
But reading the [docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#network-setup),
we just want to make sure the default route is using our static interface.

Enable Powershell execution: `Set-Executionpolicy remotesigned`. \
And run [hyperv-static-switch.ps1](hyperv-static-switch.ps1) to create a static switch in Hyper-V, with the specs:
* Name: lfclass
* Subnet: 172.30.0.0/24
* Gateway: 172.30.0.251

### Create Instances
Now we can launch our instances, using [cloud-config.yaml](cloud-config.yaml) to help configure the static IPs, and set the default route.

For most of the course, we can use:
```
multipass launch -n lfclass-cp1 --cloud-init cloud-config.yaml --disk=20G --cpus=2 --memory=2.5G --network name=lfclass,mode=manual jammy
multipass launch -n lfclass-wk1 --cloud-init cloud-config.yaml --disk=20G --cpus=1 --memory=1.5G --network name=lfclass,mode=manual jammy
```
Though for exercises on memory limits, you will need to modify the memory of the nodes, or alter the amounts used in the examples.

For the last section, on HA setup, we can additionally spin up:
```
multipass launch -n lfclass-proxy --cloud-init cloud-config.yaml --disk=20G --cpus=1 --memory=0.5G --network name=lfclass,mode=manual jammy
multipass launch -n lfclass-cp2   --cloud-init cloud-config.yaml --disk=20G --cpus=2 --memory=1.5G --network name=lfclass,mode=manual jammy
multipass launch -n lfclass-cp3   --cloud-init cloud-config.yaml --disk=20G --cpus=2 --memory=1.5G --network name=lfclass,mode=manual jammy
```

Note:
* The cloud-config does not do any Kubernetes setup. This is your job, as part of the Fundamentals course. \
  If you are not taking the course, and want to explore this separately, take a look at the [docs](https://kubernetes.io/docs/setup/production-environment/).
* I have used Ubunut 22 (jammy), without any problems. The course uses Ubuntu 20 at time of writing.
* These examples are using the minimum memory that I could get away with. Tune this if you hit issues, or have more memory to play with.
