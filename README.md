# Развертывание High Available Kubernetes кластера 

Данный playbook поможет Вам развернуть HA кластер Kubernetes.
При развертывании можно выбрать следующие параметры
-  Выбрать CRI - docker или containerd
- Выбрать развертывание с использованием nginx как loadbalancer API сервера
- Выбрать используемый CIDR


## Быстрый старт:
- устанавливаем kubelet, kubectl, kubeadm
- создаем etcd кластер
- при помощи kubeadm init создаем первого мастера сертификаты, ключи и.т.д.
- с помощью сгенерированых файлов конфигурации инициализируем остальные 4 мастер ноды
- конфигурируем балансировщик nginx на каждой мастер ноде для виртуального адреса
- меняем адрес и порт API сервера на выделенный виртуальный адрес
- Добавляем в кластер рабочие ноды


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
  - virtIp - виртуальный

## Схема развертывания:

![](https://habrastorage.org/webt/db/xm/pn/dbxmpnpsth-psiiyn_ittkfkc4a.png)
