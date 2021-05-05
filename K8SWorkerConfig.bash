#!/bin/bash

NodeName = `hostname`

swapoff –a
hostnamectl set-hostname $NodeName
