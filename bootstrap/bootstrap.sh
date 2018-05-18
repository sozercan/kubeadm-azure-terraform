#!/bin/bash

# Add hostname
echo "127.0.0.1 $HOSTNAME" >>/etc/hosts

# update and upgrade packages
apt-get update && apt-get upgrade -y

# install docker
apt-get install -y docker.io apt-transport-https

mkdir -p /etc/kubernetes /etc/kubernetes/pki /etc/systemd/system/kubelet.service.d

cat <<EOF >/etc/kubernetes/cloud-config
{
  "cloud": "AzurePublicCloud",
  "tenantId": "${TENANT_ID}",
  "subscriptionId": "${SUBSCRIPTION_ID}",
  "aadClientId": "${CLIENT_ID}",
  "aadClientSecret": "${CLIENT_SECRET}",
  "location": "${LOCATION}",
  "resourceGroup": "${RESOURCE_GROUP}",
  "vmType": "vmss",
  "subnetName": "subnet",
  "securityGroupName": "nsg",
  "vnetName": "vnet",
  "vnetResourceGroup": "",
  "routeTableName": "routetable",
  "primaryScaleSetName": "node0",
  "cloudProviderBackoff": false,
  "cloudProviderBackoffRetries": 0,
  "cloudProviderBackoffExponent": 0,
  "cloudProviderBackoffDuration": 0,
  "cloudProviderBackoffJitter": 0,
  "cloudProviderRatelimit": false,
  "cloudProviderRateLimitQPS": 0,
  "cloudProviderRateLimitBucket": 0,
  "useManagedIdentityExtension": false,
  "useInstanceMetadata": true
}
EOF

cat << EOF >/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --node-labels=${node_labels}"
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true"
Environment="KUBELET_NETWORK_ARGS=--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local"
Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt"
Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true --cert-dir=/var/lib/kubelet/pki"
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=azure --cloud-config=/etc/kubernetes/cloud-config"
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_SYSTEM_PODS_ARGS $KUBELET_NETWORK_ARGS $KUBELET_DNS_ARGS $KUBELET_AUTHZ_ARGS $KUBELET_CADVISOR_ARGS $KUBELET_CERTIFICATE_ARGS $KUBELET_EXTRA_ARGS
EOF

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y --option=Dpkg::Options::=--force-confold kubelet kubeadm kubectl

if [[ "${node_labels}" == *"role=master"* ]]; then

    echo "*** Configuring master ***"

    cat << EOF >/etc/kubernetes/azure-cloudprovider.yaml
    cloudProvider: "azure"
    kubernetesVersion: v1.10.2
    token: "${kubeadm_token}"
    networking:
      podSubnet: 10.0.2.0/24
EOF
    # initializing kubeadm
    kubeadm init --config /etc/kubernetes/azure-cloudprovider.yaml

    # copying kubeconfig
    SSH_USER="${admin_username}"
    mkdir -p "/home/$SSH_USER/.kube/"
    chown "$SSH_USER":"$SSH_USER" "/home/$SSH_USER/.kube/"
    cp "/etc/kubernetes/admin.conf" "/home/$SSH_USER/.kube/config"
    chown "$SSH_USER":"$SSH_USER" "/home/$SSH_USER/.kube/config"

    # installing calico
    kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml --kubeconfig /etc/kubernetes/admin.conf
else
    echo "*** Configuring nodes ***"

    cat <<EOF >/etc/kubernetes/azure-cloudprovider.yaml
    cloudProvider: "azure"
    kubernetesVersion: v1.10.2
EOF

    # joining node
    kubeadm join --discovery-token-unsafe-skip-ca-verification --config /etc/kubernetes/azure-cloudprovider.yaml --token "${kubeadm_token}" "${master_ip}:6443"
fi
