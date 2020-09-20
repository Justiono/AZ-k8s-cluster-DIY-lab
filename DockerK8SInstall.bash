sudo apt-get update

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo pt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# To install specific version of docker
#apt-cache madison docker-ce
#apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io

# To test
#docker run hello-world
#sudo docker run -it ubuntu bash

sudo systemctl enable docker
#sudo systemctl start docker
sudo systemctl status docker

#sudo apt-get install curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add

sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

sudo apt-get install -y kubeadm kubelet kubectl
sudo apt-mark hold kubeadm kubelet kubectl
kubeadm version

# To clean-up
#apt-get purge docker-ce docker-ce-cli containerd.io
#rm -rf /var/lib/docker
