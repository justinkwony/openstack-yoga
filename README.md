# openstack-yoga
```
------------+--------------------------+--------------------------+------------
            |                          |                          |
      enp0s3|10.10.0.11          enp0s3|10.10.0.31          enp0s3|10.10.0.41
+-----------+-----------+  +-----------+-----------+  +-----------+-----------+
|     [ controller ]    |  |       [ compute ]     |  |       [ storage ]     |
|     (Control Node)    |  |     Nova-Compute      |  |      Swift-Container  |
| MariaDB   RabbitMQ    |  |     Swift-Container   |  |      Swift-Account    |
| Memcached Swift Proxy |  |     Swift-Account     |  |      Swift-Object     |
| Keystone  httpd       |  |     Swift-Object      |  |      Cinder Volume    |
+-----------------------+  +-----------------------+  +-----------------------+
                                 sdb,sdc (swift)             sdb,sdc (swift)
                                                             sdd (cinder)
+-----------+-----------+  +-----------+-----------+  +-----------+-----------+
      enp0s8|Unconfigured        enp0s8|Unconfigured        enp0s8|Unconfigured
      enp0s9|NAT                 enp0s9|NAT                 enp0s9|NAT
```
add Network Interface 네트워크 추가\
add Storage 10Gb 저장소 추가

Create three Virtual Machines in Oracle VM Virtual Box as given in the diagrame above and set networking.
Login as user "stack" and modify all nodes
```
/etc/hosts
10.10.0.11	controller
10.10.0.31	compute
10.10.0.41	storage
```
generate ssh key pair, all nodes
```
ssh-keygen -P ""
ssh-copy-id controller
ssh-copy-id compute
ssh-copy-id storage
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
