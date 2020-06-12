# Развертывание High Available Kubernetes кластера

Данный playbook разварачивает HA кластер Kubernetes. 

## Последовательность развертывания:
- на машине, с которой запускается плейбук, создается временный каталог /tmp/k8s. Он понадобится для копирования сертификатов ETCD 
и kubernetes после инициализации первого мастера. Также в него будет добавлена строка инициализации сгенерированная kubeadmin
- на мастерах, рабочих нодах и нодах под ingress устанавливается kubelet, kubectl, kubeadm
- на мастерах, рабочих нодах и нодах под ingress установливается CRI
- на мастер нодах устанавливается ETCD. Настраивается ETCD кластер c TLS сертифкаты на мастерах в  /etc/ssl/etcd
- на первой mster ноде при помощи kubeadm init создаем первый мастер кластера сертификаты, ключи и.т.д.
- с помощью сгенерированых файлов конфигурации в кластер добавляются остальные mster nodes
- устанавливается CIDR callica
- добавляются в кластер рабочие ноды (и ingress  ноды если указанны в в группе хостов [kube_ingress])
- устанавливается haproxy как балансировщик запросов с воркеров к API
- настраивается ingress контроллер
- устанавливается helm
- выводится информация о кластере


## Быстрый старт:

```bash
git clone https://github.com/rjeka/k8s-easy-ha-cluster.git
cd k8s-easy-ha-cluster
vim hosts
```

```bash
ansible-playbook -i <inventory> main.yaml
```



