# Роль для ETCD with TSL

Запуск

ansible-playbook -i inventory/develop/hosts -l kube_masters etcd.yml  
Tags:  
ssl - генерирует сертификаты и складывает их на каждой ноде в  /etc/ssl/etcd  
etcd - ставит кластер версии указанной в GROUP_VARS/k8s  

Проверка кластера etcd:

etcdctl --endpoints="https://10.3.160.4:2379,https://10.3.160.5:2379,https://10.3.160.6:2379" --ca-file /etc/ssl/etcd/ca.pem --cert-file /etc/ssl/etcd/client.pem --key-file /etc/ssl/etcd/client-key.pem member list

etcdctl --endpoints="https://10.3.160.4:2379,https://10.3.160.5:2379,https://10.3.160.6:2379" --ca-file /etc/ssl/etcd/ca.pem --cert-file /etc/ssl/etcd/client.pem --key-file /etc/ssl/etcd/client-key.pem cluster-health
