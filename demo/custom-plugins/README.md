# 插件安装

## 安装全局插件
kubectl apply -f custom-plugins/prometheus.yaml

## 自定义插件安装
将lua编写的自定义插件以configmap的方式加载进kong的pod里，每次重新生成configmap需要重启kong的pod插件才会生效

## 生成configmap
自定义插件forward-auth-request
```
kubectl create configmap kong-forward-auth-request --from-file=custom-plugins/forward-auth-request -n kong
```
## 设置kong的环境变量
```
env:
  - name: KONG_PLUGINS
    value: forward-auth-request
```
当设置了KONG_PLUGINS环境变量时，全局插件需要加入到这个环境变量中才会生效
```
env:
  - name: KONG_PLUGINS
    value: forward-auth-request,prometheus
```
## 使插件生效
```
kubectl apply -k custom-plugins
```
