#!/bin/bash
growpart /dev/nvme0n1 4
lvextend -L +30G /dev/mapper/RootVG-varVol
xfs_growfs /var
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user
KUBECTL_VERSION="v1.34.2"

curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz"
tar -xzf eksctl_${PLATFORM}.tar.gz -C /tmp
rm -f eksctl_${PLATFORM}.tar.gz

install -m 0755 /tmp/eksctl /usr/local/bin/eksctl
rm -f /tmp/eksctl
echo 'export PATH=/usr/local/bin:$PATH' >> /etc/profile.d/custom-path.sh
chmod +x /etc/profile.d/custom-path.sh
source /etc/profile.d/custom-path.sh

hash -r
echo "Docker Version:"
docker --version

echo "Kubectl Version:"
kubectl version --client

echo "eksctl Version:"
eksctl version
mkdir -p /opt/eks


cat >/opt/eks/cluster.yaml <<'EOC'
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
    name: roboshop-dev
    region: us-east-1
managedNodeGroups:
  - name: roboshop-dev
    instanceTypes: ["t3.micro","t3.small"]
    desiredCapacity: 3 #  by default this value is 3
    spot: true
EOC

eksctl create cluster -f /opt/eks/cluster.yaml
