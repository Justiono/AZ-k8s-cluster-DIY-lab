#!/bin/bash

POD_CIDR = "10.244.0.0/16"
NodeName = `hostname`

swapoff –a
hostnamectl set-hostname $NodeName

kubeadm init --pod-network-cidr=$POD_CIDR
