#cloud-config
package_upgrade: true
packages:
- vim
runcmd:
- sudo yum update -y
- sudo yum install python-simplejson -y
