#!/bin/sh

sudo sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux

sudo yum remove -y ruby


