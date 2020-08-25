# unbound-server
unbound docker sever

[![Docker Pulls](https://img.shields.io/docker/pulls/tangcuyu/unbound-server.svg?style=plastic)](https://hub.docker.com/r/tangcuyu/unbound-server)

## 使用方法

### 准备证书文件

镜像会检查是否提供了，正确的ssl证书文件。正确的目录结构应该如下。

```shell
.
├── Dockerfile
├── entrypoint.sh
├── LICENSE
├── README.md
├── release-1.9.6.tar.gz
├── ssl
│   ├── ssl-service-key.key
│   └── ssl-service-pem.pem
└── unbound.conf
```

### 可启用的变量

- DNS_DOMAIN_NAME
  - 你的DNS域名（必要变量）
- THREADS_NUM
  - unbound 线程数（默认为2）

### 启动容器

```shell
docker run --rm -e DNS_DOMAIN_NAME="your_dns_domain" \
    -v ${PWD}/ssl:/etc/unbound/ssl \
    --privileged \
    --network=host   \
    tangcuyu/unbound-server
```

### 解析测试

在终端键入以下命令并运行。

```shell
dig github.com @127.0.0.1 -p 853

; <<>> DiG 9.14.10 <<>> github.com @127.0.0.1 -p 853
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 40410
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             12      IN      A       13.229.188.59

;; Query time: 1267 msec
;; SERVER: 127.0.0.1#853(127.0.0.1)
;; WHEN: 六 2月 08 20:36:29 CST 2020
;; MSG SIZE  rcvd: 55

dig google.com @127.0.0.1 -p 853

; <<>> DiG 9.14.10 <<>> google.com @127.0.0.1 -p 853
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 48185
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;google.com.                    IN      A

;; ANSWER SECTION:
google.com.             75      IN      A       172.217.160.110

;; Query time: 0 msec
;; SERVER: 127.0.0.1#853(127.0.0.1)
;; WHEN: 六 2月 08 20:44:54 CST 2020
;; MSG SIZE  rcvd: 55
```

## `Dockerfile`

```Dockerfile
FROM alpine:latest

RUN apk --no-cache add \
    unbound \
    openssl\
    wget\
    bash\
    && touch /var/log/unbound.log\
    && chown unbound:unbound /var/log/unbound.log

COPY ./unbound.conf /etc/unbound/unbound.conf
COPY ./entrypoint.sh /entrypoint.sh

# These commands copy your files into the specified directory in the image
# and set that as the working location
WORKDIR /

VOLUME [ "/etc/unbound/ssl/" ]

EXPOSE 853/tcp 853/udp
# This command runs your application, comment out this line to compile only
CMD ["/entrypoint.sh"]
```

### 输出示例

```shell
==================================================================
      SETTING UP ...
==================================================================

==================================================================
      INITING UNBOUND CONFIGURE FILE ...
==================================================================
----> init unbound configure file success

==================================================================
      INITING ROOT HINTS FILE ...
==================================================================
--2020-02-07 07:58:55--  https://www.internic.net/domain/named.cache
Resolving www.internic.net... 192.0.32.9, 2620:0:2d0:200::9
Connecting to www.internic.net|192.0.32.9|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3315 (3.2K) [text/plain]
Saving to: '/etc/unbound/root.hints'

     0K ...                                                   100% 9.98K=0.3s

2020-02-07 07:59:00 (9.98 KB/s) - '/etc/unbound/root.hints' saved [3315/3315]

----> init root hints file success!

==================================================================
      SET UNBOUND THREADS NUM CONF ...
==================================================================
----> set unbound threads num conf success!
----> setup complete

==================================================================
      CHECKING UNBOUND CONFIGURE /ETC/UNBOUND/UNBOUND.CONF ...
==================================================================
unbound-checkconf: no errors in /etc/unbound/unbound.conf
----> no errors in unbound configure file /etc/unbound/unbound.conf 

==================================================================
      BOOTING UNBOUND ...
==================================================================
----> unbound already started!

==================================================================
      CONTAINERD INFO
==================================================================

==================================================================
      CAT /ETC/UNBOUND/UNBOUND.CONF
==================================================================
# Unbound configuration file for Debian.
#
# See the unbound.conf(5) man page.
#
# See /usr/share/doc/unbound/examples/unbound.conf for a commented
# reference config file.
#
# The following line includes additional configuration files from the
# /etc/unbound/unbound.conf.d directory.
# include: "/etc/unbound/unbound.conf.d/*.conf"
#
server:
    directory: "/etc/unbound"
    username: unbound
    chroot: "/etc/unbound"
    use-syslog: yes
    log-time-ascii: yes
    log-queries: yes
    hide-version: yes
    pidfile: "/var/run/unbound.pid"
    interface: 0.0.0.0@853
    access-control: 0.0.0.0/0 allow
    ssl-service-key: "/etc/unbound/ssl/ssl-service-key.key"
    ssl-service-pem: "/etc/unbound/ssl/ssl-service-pem.pem"
    ssl-port: 853
    incoming-num-tcp: 1000
    udp-upstream-without-downstream: yes 
    qname-minimisation: yes #
    do-not-query-localhost: no
    val-log-level: 1
    rrset-roundrobin: yes
    prefetch: yes
    use-caps-for-id: yes
    harden-referral-path: yes
    harden-large-queries: yes
    identity: "dns2.expoli.tech"
    log-queries: yes
    do-ip6: yes
    do-ip4: yes
    ssl-upstream: yes
    root-hints: "root.hints" 
    harden-glue: yes
    so-rcvbuf: 1m
    num-threads: 2
    msg-buffer-size: 8192   # note this limits service, 'no huge stuff'.
    msg-cache-size: 100k
    msg-cache-slabs: 1
    rrset-cache-size: 100k
    rrset-cache-slabs: 1
    infra-cache-numhosts: 200
    infra-cache-slabs: 1
    key-cache-size: 100k
    key-cache-slabs: 1
    neg-cache-size: 10k
    num-queries-per-thread: 30
    target-fetch-policy: "2 1 0 0 0 0"

    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    private-address: fd00::/8
    private-address: fe80::/10

forward-zone:
    name: "."
    forward-tls-upstream: yes
    forward-addr: 8.8.8.8@853,1.1.1.1@853 #
    forward-first: yes

==================================================================
      UNBOUND IS RUNNING ...
==================================================================
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:853             0.0.0.0:*               LISTEN      33/unbound          
tcp        0      0 0.0.0.0:853             0.0.0.0:*               LISTEN      33/unbound          

; <<>> DiG 9.14.8 <<>> google.com @127.0.0.1 -p 853
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 37376
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;google.com.                    IN      A

;; ANSWER SECTION:
google.com.             299     IN      A       172.217.160.78

;; Query time: 1142 msec
;; SERVER: 127.0.0.1#853(127.0.0.1)
;; WHEN: Fri Feb 07 07:59:01 UTC 2020
;; MSG SIZE  rcvd: 55


==================================================================
      CONTAINERD IP INFO
==================================================================
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:02  
          inet addr:172.17.0.2  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:40 errors:0 dropped:0 overruns:0 frame:0
          TX packets:24 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:15491 (15.1 KiB)  TX bytes:2652 (2.5 KiB)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:3 errors:0 dropped:0 overruns:0 frame:0
          TX packets:3 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:191 (191.0 B)  TX bytes:191 (191.0 B)


==================================================================
      READY AND WAITING FOR CLIENT CONNECTIONS
==================================================================
```