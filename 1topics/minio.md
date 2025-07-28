# MinIO

* MinIO server
  * [bitnami minio](https://hub.docker.com/r/bitnami/minio)
    * Synology->Docker->Container->General Settings
      * Enable auto-restart
      * Enable web portal via Web Station
        * Port 9001 HTTP
          * Web Station: Name-based, kuku, 80
      * Advanced Settings
        * MINIO_ROOT_USER ???
        * MINIO_ROOT_PASSWORD ???
        * MINIO_BROWSER on/off
    * Synology->Docker->Container->Port Settings
      * 9000 9000 TCP
      * if not using Web Station: 9001 9001 TCP
    * Synology->Docker->Container->Volume Settings: /docker/minio /data
    * start
  * Web Station, Web Service Portal, Package Service Portal, Docker
    * Hostname: minio-console.local, Port: 80/443
* Client
  * [Quickstart](https://min.io/docs/minio/linux/reference/minio-mc.html#quickstart)
    * `mc alias set myminio https://minioserver.example.net ACCESS_KEY SECRET_KEY`
    * `mc admin info myminio`
  * [MinIO Client](https://min.io/docs/minio/linux/reference/minio-mc.html)
  * [MinIO Admin Client](https://min.io/docs/minio/linux/reference/minio-mc-admin.html)

* Synology->Control Panel->Security->Firewall->Edit Rules
  * Allow 9000, 9001 TCP from 192.168.100.51 to 192.168.100.254
  * Deny 9000, 9001 TCP from All



## TODO

* Synology->Login Portal->Advanced->Reverse Proxy
