# Развертывание High Available Kubernetes кластера 

Данный playbook разварачивает HA кластер Kubernetes.
При развертывании можно выбрать следующие параметры
-  Выбрать CRI - docker или containerd
- Выбрать развертывание с использованием nginx как loadbalancer API сервера
- Выбрать используемый CIDR


## Последовательность развертывания:
- на машине, с которой запускается плейбук, создается временный каталог /tmp/k8s. Он понадобится для копирования сертификатов после инициализации первого мастера. Также в него будет добавлена строка инициализации сгенерированная kubeadmin
- на мастерах и рабочих нодах устанавливается kubelet, kubectl, kubeadm
- на мастерах и рабочих нодах установливается CRI. Containerd или Docker (переменная criType в файле hosts. Может принимать значения docker или containerd)
- устанавливается ETCD. Настраивается ETCD кластер
- устанавливается и настраивается keepalived
- устанавливается и настраивается nginx, для балансировки между API серверами kubernetes на всех мастерах (переменная apiLoadBalancer в файле hosts. Может принимать значения true или подробности ниже)
- на master1 при помощи kubeadm init создаем первый мастер кластера сертификаты, ключи и.т.д.
- с помощью сгенерированых файлов конфигурации в кластер добавляются master2 и master3.
- устанавливается CIDR (сейчас только flanel)
- Делается scale coredns на все три мастера
- конфигурируем балансировщик nginx на каждой мастер ноде для виртуального адреса
- если использем балансировщик nginx: меняем адрес и порт API сервера на выделенный виртуальный адрес
- добавляются в кластер рабочие ноды

## Быстрый старт:

```bash
git clone https://github.com/rjeka/k8s-easy-ha-cluster.git
cd k8s-easy-ha-cluster
vim hosts
```
В файле hosts:
- в группе хостов [masters] изменить значения ansible_host на IP адреса мастеров.  
  keepalivedInterface - поменять на значение интерфейса, на котором будет работать API сервер kubernetes. На этом же       интерфейсе keepalived создаст subinterface c виртуальным IP
- в группе хостов [worknodes]  изменить значения ansible_host на IP адреса рабочих нод
- в блоке [all:vars]:
  - virtIp - виртуальный IP адрес keepalived
  - apiLoadBalancer=true если вы хотите использовать схему с балансировкой API. (false - без балансировки)
  - criType. containerd или docker, в зависимости какой CRI вы хотите использовать
  - если используется containerd criContainersVersion=1.1.0-rc.0 (now stable 1.1.0-rc.0). Если docker то можно ничего не менять
- [masters:vars]
  - СIDR=192.168.0.0/16 для установки callica
  - K8SHA_TOKEN токен для kubeadmin. Можно сгенерировать kubeadm token generate
  - etcd_version=v3.2.17 
  - etcdToken - токен etcd любое значение например 9489bf67bdfe1b4ae067d6fd9e7efefd
  - eepalivedPass - праоль keepalived любое значение например 6cf8dd754c90194d1600c483e10abfr

```bash
ansible-playbook -i hosts main.yaml
```

## Схема балансировки API:

![](https://habrastorage.org/webt/db/xm/pn/dbxmpnpsth-psiiyn_ittkfkc4a.png)
