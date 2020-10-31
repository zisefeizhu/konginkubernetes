# 网关
这里提到的网关特指API网关。API网关是在微服务架构的演进过程中产生的，其核心功能是聚合后端服务，为客户端调用提供统一的门户。由于网关的集中式管理，在其上又衍生了限流、负载、路由管理、安全防护等新的需求和功能。基于应用系统现状，我们将网关进一步的细分为带有业务逻辑的业务网关和专注于服务聚合、路由的中台网关。具体来说，业务网关一般是指某一个业务系统的网关，其除了聚合本系统的后端服务之外，还会额外承担一些业务逻辑，比如通用的用户鉴权、基于业务的路由规则等。中台网关，是跨系统的、是将已有的平台能力抽象、聚合，统一包装成API服务，以便各平台、业务复用；中台网关关注的重点是服务的路由、抽象，提供基本的身份认证、限流等功能即可，不会嵌入具体的业务逻辑。注意这里的身份认证和业务网关里的是不一样的，业务网关身份认证一般是具体的终端用户，中台网关里的身份认证是对调用方的识别、鉴权，不涉及具体终端用户。
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603676432703-70ca3671-e813-4629-b04d-88155d2f5b92.png)
# 网关产品对比

目前比较流行的API网关主要分为三类：

1、 基于NGINX的反向代理

2、 基于网络编程框架（netty、socket）自开发

3、 基于组件的API网关框架，主要有：spring cloud gateway、zuul1、zuul2

基于网络编程框架的自开发不在我们考虑范围内，主要原因有：自开发周期长，未经过实战验证可靠性需要长时间的磨合，而且自开发性能不会比已有框架表现的更好。因此我们不考虑此类情况。下面我们将分析1和3两种情况。

nginx与spring cloud gateway、zuul对比
## nginx

nginx由内核和模块组成，内核的设计非常微小和简洁，完成的工作也非常简单，仅仅通过查找配置文件与客户端请求进行URL匹配，然后启动不同的模块去完成相应的工作。下图反映了HTTP请求处理的常规流程：
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603676600695-447ff068-fa6d-46ad-8af5-b72a6a11c14c.png)

## spring cloud gateway
spring cloud gateway是在spring boot基础上构建的，用于快速构建分布式系统的通用模式的工具集。其核心也是基于filter的，可以实现类似于zuul的特性功能，但是使用spring cloud 开发的应用程序非常适合在Docker或者Paas上部署。
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603676798302-cf6d6237-234f-48f9-b191-a28220c54f81.png)

## zuul
zuul是Netflix开源的微服务网关组件，它可以和Euraka、Ribbon、Hystrix等组件配合使用。其核心是一系列的过滤器，通过这些过滤器我们可以实现身份认证、审查、监控、动态路由、压力测试、负载分配、静态影响处理、多区域弹性等。
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603676884299-7694ba99-ef2a-4015-a51e-b4bdbf010883.png)

## 对比
不难看出三者在处理请求的思想上是一致的，都是基于filter做逻辑嵌入和处理。

| 产品                | 模型                                                         | 优势                                                         | 劣势                                                         |
| :------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| nginx               | 基于进程，采用epoll_wait、select这样的I/O多路复用模型。采用了异步非阻塞的方式处理请求，理论上是可以同时处理成千上万个请求。 | 内核小巧，自身占用资源少，久经高并发考验，产品稳定、性能最好。 | 只有基本功能配置，额外的功能需要自开发插件，插件语言与一般企业开发人员差异较大，学习成本较高。 |
|                     |                                                              |                                                              |                                                              |
| spring cloud gatway | spring自己的gateway，基于Spring Boot2.x响应式的、非阻塞的API，支持WebSocket等长连接，和Spring框架紧密集成；整体模型与Nginx类似 | spring组件，与传统业务开发组件能很好集成，易于添加定制化需求，周边扩展组件丰富，学习成本较低。 | 自身资源消耗较大，在资源有限的情况下（1核2G），性能较差。相同配置下，并发的天花板要比nginx低不少。属于技术组件、没有成熟的产品，需要自开发。 |
| zuul 1              | 基于servlet框架，采用阻塞和多线程方式，存在内部延迟严重、设备故障较多情况下会引起存活连接增多和线程增加的情况发生。而且不支持如WebSocket之类的长连接 | 和其他几款相比，没有明显优势                                 | 这个没什么好说的，性能表现差、并发数小、且不支持长连接。     |
| zuul 2              | 与1相比，最大的区别是它采用了异步和无阻塞框架，每个CPU一个线程，整体模型与Nginx类似 | 有netflix的成套产品支持，常用功能容易实现，相对于nginx来说更容易定制化开发。 | 整体缺点与spring cloud类似，自身资源占用较大、低配下表现差，且需要一定的定制化开发才能使用。 |
|                     |                                                              |                                                              |                                                              |

从上面对比可以看到，各类网关都有其自身的优劣势和适用场景。对于业务网关开发，spring cloud gateway 或许是个不错的选择。中台网关，对于定制化功能要求不多，对于性能和稳定性要求是第一位的，因此nginx内核网关是个不错的选择。

基于以上原因我们选择了基于nginx内核的kong作为中台网关基座。首先，kong的内核是基于nginx的，其性能和稳定性是有保障的，而且也经过了大厂的实践验证；其次，kong是一个完整的网关产品，可以开箱即用，并且提供了丰富的插件以及简单的插件扩展机制。因此无论从性能、稳定性还是从时间成本上看，kong都是首选。

微服务五种开源API网关实现组件对比：https://blog.csdn.net/squirrelanimal0922/article/details/88946900
# kong简介及概念

Kong是Mashape开源的高性能高可用API网关和API服务管理层，在Mashape 管理了超过15,000个API，为200,000开发者提供了每月数十亿的请求支持。
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603679417225-ffb38206-0e85-4fcb-9470-15ab5b5ea2e8.png)
在微服务架构之下，按照康威定律，我们系统架构会拆的很散，系统由一堆服务组成，降低了耦合度的同时也给服务的统一管理增加了难度。 上图左边描述了在旧的服务治理体系之下，鉴权，限流，日志，监控等通用功能需要在每个服务中单独实现，这使得系统维护者没有一个全局的视图来统一管理这些功能。 Kong致力于解决的问题便是为微服务纳管这些通用的功能，在此基础上提高系统的可扩展性。如右图所示，微服务搭配上 Kong，可以使得服务本身更专注于自己的领域，很好地对服务调用者和服务提供者做了隔离。

网关所需要的基本特性，Kong 都如数支持：
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603679531311-5f340a3a-c639-445e-9e60-1288cdf8f489.png)

> - 云原生 : 与平台无关，Kong 可以从裸机运行到 Kubernetes
> - 动态路由 ：Kong 的背后是 OpenResty+Lua，所以从 OpenResty 继承了动态路由的特性
> - 熔断
> - 健康检查
> - 日志 : 可以记录通过 Kong 的请求和响应。
> - 鉴权 : 权限控制，IP 黑白名单
> - 监控 : 提供了实时监控插件
> - 认证 : 如数支持 HMAC, JWT, Basic, OAuth2.0 等常用协议
> - 限流
> - REST API: 通过 Rest API 进行配置管理，从繁琐的配置文件中解放
> - 可用性 : 天然支持分布式
> - 高性能 : 背靠非阻塞通信的nginx，性能高
> - 插件机制 : 提供众多开箱即用的插件，且有易于扩展的自定义插件接口，用户可以使用 Lua 自行开发插件

Kong整体架构如下所示：
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603679824243-d7313f76-2d51-42a0-9975-edded7d876e7.png)

从技术的角度讲，Kong可以认为是一个OpenResty应用程序。 OpenResty 运行在 Nginx 之上，使用 Lua 扩展了 Nginx。 Lua 是一种非常容易使用的脚本语言，可以让你在Nginx中编写一些可以执行的操作。

> - Kong核心基于OpenResty、nginx构建，用来接收 API 请求；
> - Kong插件拦截请求/响应，进行处理；
> - 提供 restfull 方式管理 admin api；
> - 数据库存储Kong集群节点信息、API、消费者、插件等信息，目前提供了PostgreSQL和Cassandra支持。

Kong 抽象了一些概念Route、Service、Upstream、Consumer等，他们之间的关系如下图所示 :
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603679954307-a53f3697-0943-404e-9f99-f778ff2254d7.png)

> - Route 路由相当于nginx 配置中的location Route实体定义匹配客户端请求的规则. 每个路由都与一个服务相关联,而服务可能有多个与之相关联的路由. 每一个匹配给定路线的请求都将被提交给它的相关服务. 路由和服务的组合提供了强大的路由机制, 可以在Kong中定义细粒度的入口点,从而引导访问到不同upstream服务
> - service 是抽象层面的服务，他可以直接映射到一个物理服务 (host 指向 ip + port)，也可以指向一个 upstream 来做到负载均衡,一个Service可以有很多Route,匹配到的Route就会转发到Service中
> - upstream 是对上游服务器的抽象；target 代表了一个物理服务，是 ip + port 的抽象
> - Consumer 对象表示服务的使用者或者用户。最简单的理解和配置consumer的方式是,将其于用户进行一一映射,即一个consumer代表一个用户（或应用），但如果你将几个应用定义统一个consumer,这些都可以。

# 插件机制与常用插件说明
openresty定义的请求生命周期如下:

![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603680164089-2b4af149-a644-4eb2-87d2-793047cc8605.png)
Kong插件遵循严格的文件结构，即包命，类名，文件位置等组织代码的方式是固定的，详细的文件结构如下图所示:

![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603680223224-90f5216e-d7ad-4c83-a474-6cf5cfa48233.png)

Kong 提供了一个基类，允许开发者覆盖类中提供的方法，这些方法的本质是openresty定义的请求生命周期，可以在request/response 的生命周期中的几个入口点注入自定义逻辑。每一个方法有一个config参数，这个参数即schema.lua 中声明的，在使用插件时的配置。详细的逻辑如下图所示:

![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603680314954-7e522638-dd3b-451d-8aaa-a7dd67ed3c2d.png)

Kong 默认自带的插件集，按照功能的不同大致可以分为以下这些类：Authentication 认证、Security 安全、Serverless、Traffic Control 流量控制、Analytics & Monitoring 分析监控、Transformations 请求报文处理、Logging 日志等

我们目前用到的插件如下：

| 类别     |       插件名        | 使用场景                                                     |
| :------- | :-----------------: | ------------------------------------------------------------ |
| 认证     |      key-auth       | 对于服务或者路由提供用关键字认证机制                         |
| 认证     |         jwt         | 提供JWT(JSON WEB Token)的认证方式                            |
| 安全     |         acl         | 通过ACL(Access Control List)的组名称对服务或者路由进行黑白名单的访问控制 |
| 日志     |       tcp-log       | 发送请求和响应日志到TCP服务器                                |
| 流量控制 |    rate-limiting    | 提供对给定时间请求数目的控制功能                             |
| 流量控制 | request-termination | 根据响应的状态码和信息，可停止对某个服务或者路由的流量       |
| 监控     |     prometheus      | 暴露kong的metric endpoint                                    |

# 部署架构

![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603681607106-3c93deb1-5860-4828-a951-80c69838576b.png)

# 压力测试
## 基础配置
| 服务     | 配置说明                                |
| :------- | --------------------------------------- |
| SLB      | 阿里云SLB，QPS:10000，IP：10.163.240.30 |
| kong     | 单节点独立部署，4核8G，IP:10.163.204.90 |
| 负载均衡 | compass负载均衡,IP:10.163.204.8         |
| 后端服务 | 容器化部署，0.3核，400m                 |
| 日志服务 | 1核，2G                                 |
| ES       | ES集群，3台，16核64G                    |
## 服务说明
后端服务是标准Spring Boot服务，部署在Compass平台，没有做额外业务逻辑，提供以下接口

> - /api/v1/quick:直接返回计数，不错额外处理

> - /api/v1/slown:直接返回计数，但会延迟3~10秒钟，该值为随机值
## 测试网络拓扑
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603682159562-2aa1469f-0faa-4118-aad7-f3cb1e306420.png)
## 吞吐量测试
jmeter测试软件，进行吞吐量测试，测试样本为1000并发，1000次轮询，即100w次调用。以下是测试结果统计：

| 序号 | 测试用例                   | 总耗时 | 最小耗时 | 最大耗时 | 平均耗时 | CPU_start | CPU_end | memory_start | memory_end | memory_max | 备注                                                         |
| :--- | -------------------------- | ------ | -------- | -------- | -------- | --------- | ------- | ------------ | ---------- | ---------- | ------------------------------------------------------------ |
| 1    | 直连服务，不经过网关       | 161s   | 1ms      | 496ms    | 156ms    | -         | -       | -            | -          | -          | -                                                            |
| 2    | 网关+服务+logstash日志服务 | 168s   | 2ms      | 6255ms   | 161ms    | 0.2       | 37.8    | 28.3         | 55.3       | 70.4       | 日志服务滞后服务吞吐量，日志写完约用时8分钟;且在日志写入期间网关内存持续上升 |
| 3    | 网关+服务+filebeat日志服务 | 163s   | 2ms      | 5286ms   | 155ms    | 0.2       | 44.9    | 10.8         | 11.2       | 11.2       | 日志滞后约1分钟，耗时3分半。无其他明显影响                   |
| 4    | 网关+服务                  | 161s   | 2ms      | 5134ms   | 156ms    | 0.2       | 34.8    | 8.9          | 9.2        | 9.2        | -                                                            |
| 5    | 短连接+https+网关+filebeat | 561s   | 2ms      | 255ms    | 128ms    | 0.2       | 25.1    | 9.3          | 9.1        | 9.3        | 在短链接情况下，吞吐量为2000/s所以耗时较长，但是每条的耗时并没有受到太大影响 |
| 6    | 短连接+http+网关+filebeat  | 160s   | 2ms      | 4988ms   | 156ms    | 0.2       | 44.4    | 11.2         | 10.8       | 11.2       | 关闭SLB的https协议转换之后，吞吐量明显提升，与上文长连接测试结果一致 |
### 网关+服务+logstash日志服务内存/CPU变化曲线
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603684001523-44f390f6-bee4-4098-841e-59294dc7a330.png)

从上图不难看出，在客户端访问结束（3.5分钟）时，CPU占用就开始明显下降，但是由于日志服务处理效率跟不上，网关内存却继续上升，最高占用70%左右，随后下降。从这里不难看出，logstash日志处理方案，在大吞吐量时会成为瓶颈，进而影响网关机器。
### 网关+服务+filebeat日志服务内存/CPU变化曲线
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603684073279-37368937-870c-4f42-8d22-186b9a44d91c.png)

从上图看，filebeat对于网关内存几乎没有影响，实际测试中，filebeat日志吞吐量约为4200/s，滞后网关吞吐量，但是并不会造成额外的内存开销。
### 网关+服务内存/CPU曲线
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603684229578-ca1659f9-eb19-4d8e-b51e-a4f83a681d23.png)
### 日志相关横向对比
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603684431446-13479e84-a53d-4a03-8f8e-ee4bd904cc2a.png)

从上图不难看出，就网关本身的吞吐量看，三者基本是一致的。logstash日志服务，会有较大的额外内存开销和较小的CPU开销；filebeat几乎没有额外的内存开销，仅有少量的CPU开销。 综上在大吞吐量及日志需求下，filebeat是个不错的选择。
### 性能结果
经过对比和统计测试数据，发现kong本身，在启用插件的情况下，额外的性能损耗约为0.11ms。

需要注意的是，由于我们使用的是阿里云的SLB，在https和短连接并发的情况下，会带来比较严重的性能损失，因此在实际应用中，需要根据API安全级别去考虑策略。
## 并发测试
1、测试方案

基本配置与吞吐量测试一致。资源所限，很难达到nginx的访问瓶颈（这也从侧面说明了nginx内核的强大）.我们修改了kong的nginx配置项,将连接上限改为100.
```
nginx_work_processes=1
nginx_events_work_connections=100
```
2、测试结论

我们以100并发访问后端应用，后端应用耗时在3~10秒之间随机。测试中发现当并发数达到40左右就达到了上限。这时网关其他服务也不可用，范文均返回502；直至测试结束才逐步恢复。 因此可以推断出，在规模化场景中，低质的后端服务会对网关自身的运行造成影响，严重的情况下会是致命的。我们在设计网关的高可用方案时要考虑此类情况。
# kong高可用
## 部署方案
参考《部署架构》章节，我们采用集群模式部署。该模式允许我们水平的扩展集群大小，以应对不同的流量。从kong的设计上讲其水平扩展是平滑且简单的。唯一的影响就是，它是基于数据库做的一致性，为了提高效率，所有数据是缓存在内存中的，因此在一致性上会存在一定的延迟（5S左右）。集群前端我们采用阿里云的SLB作为负载均衡，以保证整个集群的高可用。
## 运行监控
结合prometheuse以及告警平台实现网关集群运行状态的监控。

具体来说就是启用prometheuse插件，将Kong与上游服务的相关指标，以prometheuse exposition的形式公开。prometheuse集群会对这些指标进行抓取。主要指标包括：
> - 节点内存占用情况
> - API服务请求数
> - API响应耗时
> - 当前活跃连接数
> - 数据存储是否可达
> - 基于指标，指定相关告警规则，通过告警平台，实现集群运行状态监控。
## 服务管理
上文提到了，上游低质服务会对网关本身的可用性造成影响，严重情况下会导致网关宕机。作为服务中枢的网关一旦宕机，后果将是灾难性的。因此对于上游服务的管理和监控是必要的。目前主要从以下三个方面着手：
### 启用健康检查
我们通过启用上游的健康检查，来实现对后端服务可用性的实时监测，以便kong及时发现异常服务，并终止到其的路由。kong提供两类健康检查:

1.主动健康检查（active）

主动健康检查是指，上游服务提供一个心跳接口，由空定时调用，当达到指定阈值时，就认定服务不可用；

同时根据设置的阈值，一旦服务达到健康阈值，kong会自动恢复对该服务的路由。
```
优点：与实际运行无关，由kong主动探查服务，可以及时发现异常，并能自动恢复。

缺点：该方案会对上游服务带来额外的流量消耗。
```
2.被动健康检查（passive）

被动健康检查是指，kong不会主动心跳上游服务，而是根据实际路由情况，结合设置的阈值来判断服务是否可用。
```
优点：不会对上游服务带来任何影响

缺点：一旦异常，服务不能自动恢复，而且异常的发现取决于实际的路由访问情况，不能及时发现
```
### 启用限流插件（rate limiting）
限流插件，顾名思义就是对后端服务的访问流量进行限制。kong提供了灵活的限流策略，他允许我们对消费者访问某个服务、API进行限制。提供了多种级别的阈值设置。该插件可以有效的拦截恶意攻击请求。
### 服务隔离
我们通过配置SLB策略，将低质服务全部负载到独立的网关集群，使其与其他服务在物理上隔离，以避免其可能带来的雪崩。
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603692670404-43fdcc77-72c7-4ab2-a5d7-7bc9193ab733.png)
# 调用日志收集流程
Kong的日志插件中我们选用http-log，原理是设置一个log-server地址，Kong会将日志通过post请求发送到设置的log-server，然后log-server把日志给沉淀下来。 这里的log-server我们使用logstash实现,将收集到的日志发送到ES中。

日志收集流程如下：
![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603692910855-a44a515c-d190-4693-8d9b-37306f523dfa.png)

logstash计划根据集群地域不同分别部署，青岛集群共用一套，北京集群另外搭建。 青岛kong集群分为测试和生产环境，logstash将开放两个http服务端口，9000对应接收测试环境日志，9001对应接收生产环境日志。 根据端口数据来源不同，logstash将日志存储到es的不同索引上，用以区分环境信息。
## logstash配置文件
logstash青岛集群服务部署在容器云内， 所有配置文件都使用配置文件挂载的形式,方便修改配置。

![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603693053931-82b6e77d-c09d-4151-9345-7c846d655cbf.png)
## kong日志结构
官方文档地址：https://docs.konghq.com/hub/kong-inc/http-log/

每次请求都会以JSON形式的内容记录,格式如下:
```
{
    "request": {
        "method": "GET",
        "uri": "/get",
        "url": "http://httpbin.org:8000/get",
        "size": "75",
        "querystring": {},
        "headers": {
            "accept": "*/*",
            "host": "httpbin.org",
            "user-agent": "curl/7.37.1"
        },
        "tls": {
            "version": "TLSv1.2",
            "cipher": "ECDHE-RSA-AES256-GCM-SHA384",
            "supported_client_ciphers": "ECDHE-RSA-AES256-GCM-SHA384",
            "client_verify": "NONE"
        }
    },
    "upstream_uri": "/",
    "response": {
        "status": 200,
        "size": "434",
        "headers": {
            "Content-Length": "197",
            "via": "kong/0.3.0",
            "Connection": "close",
            "access-control-allow-credentials": "true",
            "Content-Type": "application/json",
            "server": "nginx",
            "access-control-allow-origin": "*"
        }
    },
    "tries": [
        {
            "state": "next",
            "code": 502,
            "ip": "127.0.0.1",
            "port": 8000
        },
        {
            "ip": "127.0.0.1",
            "port": 8000
        }
    ],
    "authenticated_entity": {
        "consumer_id": "80f74eef-31b8-45d5-c525-ae532297ea8e",
        "id": "eaa330c0-4cff-47f5-c79e-b2e4f355207e"
    },
    "route": {
        "created_at": 1521555129,
        "hosts": null,
        "id": "75818c5f-202d-4b82-a553-6a46e7c9a19e",
        "methods": null,
        "paths": [
            "/example-path"
        ],
        "preserve_host": false,
        "protocols": [
            "http",
            "https"
        ],
        "regex_priority": 0,
        "service": {
            "id": "0590139e-7481-466c-bcdf-929adcaaf804"
        },
        "strip_path": true,
        "updated_at": 1521555129
    },
    "service": {
        "connect_timeout": 60000,
        "created_at": 1521554518,
        "host": "example.com",
        "id": "0590139e-7481-466c-bcdf-929adcaaf804",
        "name": "myservice",
        "path": "/",
        "port": 80,
        "protocol": "http",
        "read_timeout": 60000,
        "retries": 5,
        "updated_at": 1521554518,
        "write_timeout": 60000
    },
    "workspaces": [
        {
            "id":"b7cac81a-05dc-41f5-b6dc-b87e29b6c3a3",
            "name": "default"
        }
    ],
    "consumer": {
        "username": "demo",
        "created_at": 1491847011000,
        "id": "35b03bfc-7a5b-4a23-a594-aa350c585fa8"
    },
    "latencies": {
        "proxy": 1430,
        "kong": 9,
        "request": 1921
    },
    "client_ip": "127.0.0.1",
    "started_at": 1433209822425
}
```
> - request 包含客户端发送的请求内容
> - response 包含发送到客户端的响应内容
> - tries 包含负载均衡器为此请求进行的（重新）尝试（成功和失败）列表
> - route 包含请求匹配的route信息
> - service 包含请求匹配的service信息
> - authenticated_entity 包含身份验证的凭据属性（如果已启用身份验证插件）
> - workspaces 包含路由关联的工作空间的Kong属性（仅限Kong Enterprise版本> = 0.34）
> - consumer 包含消费者认证信息（如果已启用身份验证插件）
> - proxy 是最终服务处理请求所花费的时间
> - kong 是运行所有插件所需的内部Kong延迟
> - request 是从客户端读取的第一个字节之间以及最后一个字节发送到客户端之间经过的时间。用于检测慢速客户端
> - client_ip 包含原始客户端IP地址
> - started_at 包含开始处理请求的UTC时间戳
## filter插件
## Pre Filter
配置一个webhook，网关根据返回响应码决定是否继续执行路由。
### 在Service启用插件
通过发出以下请求在Service上配置次插件
```
$ curl -X POST http://kong:8001/services/{service}/plugins \
    --data "name=pre-filter"  \
    --data "config.http_endpoint=http://mockbin.org/bin/:id" \
    --data "config.header_names=headers" \
    --data "config.timeout=1000" \
    --data "config.keepalive=1000"
```
{service}是此插件配置将定位的Service的id或name
### 在Route上启用插件
```
$ curl -X POST http://kong:8001/routes/{route}/plugins \
    --data "name=pre-filter"  \
    --data "config.http_endpoint=http://mockbin.org/bin/:id" \
    --data "config.header_names=headers" \
    --data "config.timeout=1000" \
    --data "config.keepalive=1000"
```
{route}是此插件配置将定位的Route的id或name
### 全局插件
后面结合k8s进行演示
### 参数
以下是此插件使用的参数列表

| 参数                 |    默认值     | 说明                                   |
| :------------------- | :-----------: | -------------------------------------- |
| name                 |               | 要启用的插件的名称，本例中为pre-filter |
| service_id           |               | 此插件定位的Service的Id，可以为空      |
| route_id             |               | 此插件定位的Route的ID，可以为空        |
| enabled              |     true      | 是否应用此插件                         |
| config.http_endpoint |               | 将要调用的webhook地址，需要是GET请求   |
| config.timeout       |     1000      | 调用服务的超时时间，默认是1000ms       |
| config.header_names  | authorization | 需要转发的请求头信息                   |
### 使用
该插件处于路由转发的前置位置。在请求到来时，会根据header_names配置，从请求头中获取对应的信息，并封装到新的请求中，发送到指定的http_endpoint。根据返回状态码来判断是否继续执行。
> - 200 表示通过，会继续执行后续操作
> - 302 表示通过，会继续执行后续操作
> - 大于等于400，表示不通过，会阻断请求，返回401到前端；注意如果http_endpoint出现异常，也会阻断请求。
# 裸机部署kong
kong 搭建手册
## 环境检查
操作系统版本
```
lsb_release -a
内核版本
uname -a
记录好系统版本
```
## kong安装
```
在yum源配置完善的情况下可以直接执行
$ sudo yum install epel-release
$ sudo yum install kong-2.0.2.el7.amd64.rpm --nogpgcheck
如果yum源配置有问题，可以手动指定远程资源安装
安装epel-release软件包，以便Kong可以获取所有必需的依赖项：
$ EL_VERSION=`cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+'`
$ sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${EL_VERSION%.*}.noarch.rpm
安装Kong 对应的packages可以从https://docs.konghq.com/install/centos/#packages 对照系统版本选择：
$ sudo yum install -y https://bintray.com/kong/kong-rpm/download_file?file_path=centos/7/kong-2.0.2.el7.amd64.rpm --nogpgcheck
```
## 部署
```
修改配置数据库
cp /etc/kong/kong.conf.default  /etc/kong/kong.conf
vi /etc/kong/kong.conf
grep -E "pg|post" /etc/kong/kong.conf
database = postgres             # Determines which of PostgreSQL or Cassandra
                                 # Accepted values are `postgres`,
pg_host = 127.0.0.1             # Host of the Postgres server.
pg_port = 5432                  # Port of the Postgres server.
pg_timeout = 5000               # Defines the timeout (in ms), for connecting,
pg_user = kong                  # Postgres user.
pg_password = 123456                  # Postgres user's password.
pg_database = kong              # The database name to connect to.
初始化数据库
kong migrations bootstrap            #集群其中一个节点配置完成即可，其余节点无需重复执行
启动
kong start
检查状态
kong  health
```
所有节点启动完成之后，可以自主部署nginx负载，至此集群部署完成。
# 在k8s上部署kong

| 组件    |  版本  |
| :------ | :----: |
| kubectl | 1.16.9 |
| kong    |  2.0   |
## Kong Gateway中的流量
默认情况下，Kong Gateway在其配置的代理端口8000和8443上侦听流量。它评估传入的客户端API请求，并将其路由到适当的后端API。在路由请求和提供响应时，可以根据需要通过插件应用策略。

例如，在路由请求之前，可能需要客户端进行身份验证。这带来了许多好处，包括：

> - 由于Kong Gateway正在处理身份验证，因此该服务不需要自己的身份验证逻辑。
> - 该服务仅接收有效请求，因此不会浪费周期来处理无效请求。
> - 记录所有请求以集中查看流量。

```
plantuml
@startuml 
"API CLIENT" -> "KONG GATEWAY": REQUESTS
activate "KONG GATEWAY"
"KONG GATEWAY" -> "BACKEND API": REQUESTS
"BACKEND API" -> "KONG GATEWAY": RESPONSES
"KONG GATEWAY" -> "API CLIENT": RESPONSES
deactivate "KONG GATEWAY"
@enduml
```
kong中的插件

![image](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603700297073-a3b38db9-9e32-4f50-9168-e24df3f9d417.png)

## 转发时序图
```
plantuml
@startuml
"API CLIENT" -> "KONG GATEWAY": REQUESTS
activate "KONG GATEWAY"
"KONG GATEWAY" -> "KONG GATEWAY": "forward-plugin"
"KONG GATEWAY" -> "AUTH BACKEND SERVER": REQUEST
"AUTH BACKEND SERVER" -> "KONG GATEWAY": RESPONSES
"KONG GATEWAY" -> "KONG GATEWAY": "forward-plugin"
"KONG GATEWAY" -> "BACKEND API": REQUESTS
"BACKEND API" -> "KONG GATEWAY": RESPONSES
"KONG GATEWAY" -> "API CLIENT": RESPONSES
deactivate "KONG GATEWAY"
@enduml
```
## 安装部署流程
```
kubectl apply -k manifests/base
```
查看po状态
```
# kubectl get po -n kong
NAME                            READY   STATUS    RESTARTS   AGE
ingress-kong-7f8f64c5fc-xrsbg   2/2     Running   1          17m

```
查看svc
```
# kubectl get svc -n kong
NAME                      TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                     AGE
kong-proxy                LoadBalancer   10.96.178.210    <pending>     80:32724/TCP,443:31298/TCP,8100:32415/TCP   25m
kong-validation-webhook   ClusterIP      10.104.253.149   <none>        443/TCP                                     25m
```
运行以下命令
```
# export PROXY_IP=$(kubectl get -o jsonpath="{.spec.clusterIP}" service kong-proxy -n kong)
```
这个时候访问kong服务，响应头包含kong信息。
```
curl -i $PROXY_IP
```
### 运行两个测试服务

以本demo为例，构建服务镜像
```
docker build -t kong-test-server apps/test/
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603705715596-90713d58-caf9-4054-8f2d-dac8980039f7.png)
```
docker build -t kong-auth-server apps/auth/
```
在kubernetes环境跑起来
```
kubectl apply -f apps/test/test.yaml
kubectl apply -f apps/auth/auth.yaml
```
访问服务

可以看到结果如下，流量经过kong访问到了test和auth
```
curl -i $PROXY_IP/test/
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603705822966-1d2adcfb-8ef9-425d-9af7-be69ce2ce006.png)
```
curl -i $PROXY_IP/auth/
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603705876090-6825bf8c-4f58-4a7c-85c1-c33efbb1b49c.png)
### 使用官方插件
设置局部插件

> - 注：设置在Ingress或Service，都能使插件生效。以下以Ingress为例，Service同。

查看Ingress资源，可以看到刚刚创建的两个Ingress资源
```
kubectl get ingress
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603705973200-1b3a2eb5-e565-4711-94c4-cd315970a5e6.png)

声明官方插件
```
$ echo '
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: add-response-header
config:
  add:
    headers:
    - "demo: injected-by-kong"
plugin: response-transformer
' | kubectl apply -f -
```

将官方插件与Ingress规则相关联
```
kubectl patch ingress kong-test-server -p '{"metadata":{"annotations":{"konghq.com/plugins":"add-response-header"}}}'
```
查看ingress信息
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603706052668-332df904-c7c8-41a2-a8b4-b4075b4b7c6e.png)
访问服务，可以看到响应头多了刚刚插件的信息
```
curl -i $PROXY_IP/test/
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603706116605-9ff28437-061a-4f71-a697-fe573fdb8630.png)
设置全局插件
```
$ echo "
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: global-rate-limit
  labels:
    global: \"true\"
config:
  minute: 5
  limit_by: consumer
  policy: local
plugin: rate-limiting
" | kubectl apply -f -
```
查看插件资源
```
kubectl get kp -A
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603706195298-0dafed63-14f1-49d7-a4b9-992d70def1b4.png)
再次访问服务，响应头多了全局插件信息（全局插件不需要在指定ingress或service配置注解）
```
curl -i $PROXY_IP/test/
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603706268786-2bf8420a-0601-475c-aaa7-ffb153347716.png)
### 安装自定义插件
本demo使用lua实现了两个自定义插件：
> - my-custom-plugin：根据配置文件返回指定响应头
> - request-uri-pass-auth：根据配置文件，配置路由白名单，对不符合路由白名单规则的请求作拦截

为插件代码创建ConfigMap

以ConfigMap的方式将插件加载进kong服务里

下面创建这2个自定义插件
```

kubectl create configmap kong-plugin-myheader --from-file=demo/custom-plugins/myheader -n kong
kubectl create configmap kong-plugin-request-uri-pass-auth --from-file=demo/custom-plugins/request-uri-pass-auth -n kong
```
查看创建的configmap
```
kubectl get configmap -n kong
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603706383067-ec980a9c-8c69-46d6-b272-d633f8ae9ce9.png)
#### 更新kong Deployment资源
要使用自定义插件，需要新增自定义插件环境变量，并且将上述生成的插件代码以ConfigMap的方式映射到kong中。
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingress-kong
  namespace: kong
spec:
  template:
    spec:
      containers:
      - name: proxy
        env:
        - name: KONG_PLUGINS
          value: request-uri-pass-auth,myheader
        - name: KONG_LUA_PACKAGE_PATH
          value: "/opt/?.lua;;"
        volumeMounts:
        - name: plugin-request-uri-pass-auth
          mountPath: /opt/kong/plugins/request-uri-pass-auth
        - name: my-custom-plugin
          mountPath: /opt/kong/plugins/myheader
      volumes:
      - name: plugin-request-uri-pass-auth
        configMap:
          name: kong-plugin-request-uri-pass-auth
      - name: my-custom-plugin
        configMap:
          name: kong-plugin-myheader
```
更新kong Deployment资源
```
kubectl apply -k demo/custom-plugins/
```
创建Kong Plugin自定义资源

分别对刚刚2个插件创建Kong Plugin

myheader.yaml
```
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: my-custom-plugin
config:
  header_value: "my first plugin"
plugin: myheader
```
request-uri-pass-auth.yaml
```
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: request-uri-pass-auth
config:
  prefixs:
  - "/open/"
plugin: request-uri-pass-auth

# kubectl apply -f demo/custom-plugins/myheader/myheader.yaml
kongplugin.configuration.konghq.com/my-custom-plugin created

# kubectl apply -f demo/custom-plugins/request-uri-pass-auth/request-uri-pass-auth.yaml
kongplugin.configuration.konghq.com/request-uri-pass-auth created
```
#### 查看Kong Plugin
可以看到官方的Kong Plugin和自定义Kong Plugin
```
kubectl get KongPlugin -A
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603706598103-9e1eb0bc-ad63-4040-a755-976053dfacb1.png)
> > 注意！这里有一个坑！当使用自定义插件的时候。我们需要声明KONG_PLUGINS环境变量，这会导致官方的插件失效。这个时候需要将官方插件也加入到声明的KONG_PLUGINS中。

官方插件失效后访问设置了官方插件注解的服务时返回以下结果
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603706753619-e571fade-9fa1-4655-ad15-2dd2a7f8d0e3.png)
以本demo为例，完整的yaml应该为: custoem-plugin.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingress-kong
  namespace: kong
spec:
  template:
    spec:
      containers:
      - name: proxy
        env:
        - name: KONG_PLUGINS
          value: request-uri-pass-auth,myheader,response-transformer,rate-limiting
        - name: KONG_LUA_PACKAGE_PATH
          value: "/opt/?.lua;;"
        volumeMounts:
        - name: plugin-request-uri-pass-auth
          mountPath: /opt/kong/plugins/request-uri-pass-auth
        - name: my-custom-plugin
          mountPath: /opt/kong/plugins/myheader
      volumes:
      - name: plugin-request-uri-pass-auth
        configMap:
          name: kong-plugin-request-uri-pass-auth
      - name: my-custom-plugin
        configMap:
          name: kong-plugin-myheader
```
更新kong Deployment资源
```
kubectl apply -k demo/custom-plugins/
```

#### 测试
测试自定义插件是否生效

为test服务添加request-uri-pass-auth插件
```
kubectl patch ingress kong-test-server -p '{"metadata":{"annotations":{"konghq.com/plugins":"request-uri-pass-auth"}}}'
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603707000720-7109cd36-423b-4853-8d49-911d8c27ef1f.png)
为auth服务添加my-custom-plugin插件
```
kubectl patch ingress kong-auth-server -p '{"metadata":{"annotations":{"konghq.com/plugins":"my-custom-plugin"}}}'
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603707065972-c1de1468-a365-419e-96ae-85e14269215f.png)


测试自定义插件是否生效

访问test服务
```
curl -i $PROXY_IP/test/
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603707176285-0e5cb260-3d29-4d13-aa4f-863d448588a2.png)
可以看到/test/路由被"request-uri-pass-auth"插件拦截
```
curl -i $PROXY_IP/open/
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603707234691-7c0a98c4-f88f-4138-8aba-c5ede027c998.png)
可以看到，/open/路由没有被拦截，因为"request-uri-pass-auth"插件对/open/路由作了放行。然后还放回了全局插件"rate-limit"信息。自定义插件和官方对全局插件生效。

访问auth服务
```
curl -i $PROXY_IP/auth/
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603707296812-52ef2d36-0b50-422e-920d-f7ca8a8c6f36.png)

可以看到，返回了"my-custom-plugin"插件信息和"rate-limit"插件信息。自定义插件和官方全局插件生效。
> > 注意！KongPlugin资源需要跟对应的svc或ingress处于同一个命名空间。本demo都是声明在default空间。

## aliyun上使用kong

创建slb
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1603707556122-fee57283-010c-4c84-b852-981356afd482.png)
修改manifests/base/service.yaml
```
...
metadata:
  name: kong-proxy
  namespace: kong
  annotations:
    
    ## ALIYUN SLB
    service.beta.kubernetes.io/alibaba-cloud-loadbalancer-id: lb-wz9nc7r25b64p97r2gpke
    service.beta.kubernetes.io/alicloud-loadbalancer-address-type: internet
...
```
## 安装官方插件之prometheus插件
综合demo/custom-plugins/README.md 以及manifests/base/kong-ingress-dbless.yaml和manifests/base/service.yaml


