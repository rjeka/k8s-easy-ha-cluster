# Роль для ETCD with TSL

Запуск

ansible-playbook -i inventory/develop/hosts -l kube_masters etcd.yml  
Tags:  
ssl - генерирует сертификаты и складывает их на каждой ноде в  /etc/ssl/etcd  
etcd - ставит кластер версии указанной в GROUP_VARS/k8s  


etcdctl --endpoints="https://10.73.70.188:2379,https://10.73.71.124:2379,https://10.73.71.124:2379" --ca-file /etc/ssl/etcd/ca.pem --cert-file /etc/ssl/etcd/client.pem --key-file /etc/ssl/etcd/client-key.pem member list  
