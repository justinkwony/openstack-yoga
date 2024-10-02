# openstack-yoga
```
------------+--------------------------+--------------------------+------------
            |                          |                          |
      enp0s3|10.0.0.11,12,13     enp0s3|10.0.0.14,15        enp0s3|10.0.0.xx    for management
+-----------+-----------+  +-----------+-----------+  +-----------+-----------+
|     [ controller ]    |  |      [ compute ]      |  |      [ storage ]      |
|     (Control Node)    |  |     Nova-Compute      |  |     Swift-Container   |
| MariaDB   RabbitMQ    |  |     Neutron-agent     |  |     Swift-Account     |
| Memcached Swift Proxy |  |                       |  |     Swift-Object      |
| Keystone  httpd       |  |                       |  |     Cinder Volume     |
+-----------------------+  +-----------------------+  +-----------------------+
                                                             sdb,sdc (swift)
                                                             sdd (cinder)
+-----------+-----------+  +-----------+-----------+  +-----------+-----------+
      enp0s8|unmanaged           enp0s8|unmanaged           enp0s8|unmanaged    for provider
      enp0s9|NAT                 enp0s9|NAT                 enp0s9|NAT          (option)
```
add Network Interface 네트워크 추가\
add Storage 10Gb 저장소 추가

Create three Virtual Machines in Oracle VM Virtual Box as given in the diagrame above and set networking.
Login as user "stack" and modify all nodes
```
/etc/hosts
10.0.0.11	controller controller1
10.0.0.12	controller2
10.0.0.13	controller3
10.0.0.14	compute1
10.0.0.15	compute2
10.0.0.xx	storage
```
generate ssh key pair, all nodes
```
ssh-keygen -P ""
ssh-copy-id controller
```
```
git clone https://github.com/justinkwony/openstack-yoga.git
```
인터넷 다운로드가 필요한 파일을 미리 받아서 로컬에서 제공하도록 수정
```
cd scripts
# stack@controller:~/scripts$ ./pre-download.sh
# 미리 준비 controller/scripts/img
cd ubuntu
```
Ubuntu Cloud image로 변경
https://cloud-images.ubuntu.com/jammy/

Execute the scriptes in the given order:
```
cd ubuntu
stack@controller:~/scripts/ubuntu$ ./batch_1.sh
```
Don't Execute the script batch_2.sh as of now.

On Compute Node, execute the scripts in  the following order.
```
stack@compute:~/scripts/ubuntu$ ./batch_1.sh
```
install nova, neutron, swift

One Storage Node, execute the scripts in  the following order.
```
stack@storage:~/scripts/ubuntu$ ./batch_1.sh
```
install cinder, swift

Back to controller node, execute the following script
```
stack@controller:~/scripts/ubuntu$ ./batch_2.sh
```
Create public network, private network and router
```
stack@controller:~/scripts/ubuntu$ cd ..
stack@controller:~/scripts$ ./config_public_network.sh
stack@controller:~/scripts$ ./config_private_network.sh
```
