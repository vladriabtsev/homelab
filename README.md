# Homelab

## Network services

* [My Wiki](http://office.local/mediawiki)
* [Longhorn UI, ip:101](http://longhorn.local)
* Minio
  * [MinIO server](./1topics/minio.md), http, office.local:9000, 192.168.100.227:9000, only from 192.168.100.0
  * TODO [MinIO server console (if ON), http](http://office.local:9001), 192.168.100.227:9001, only from 192.168.100.0
* [Gitea UI, ip:103](http://gitea.local)
* [Jenkins UI, ip:109](http://jenkins.local)
* DB DEV
  * [PGADMIN, ip:111](http:pgadmin.local)
  * [PG15, ip:112](pg15.local)
  * [PG16, ip:113](pg16.local)
  * [PG17, ip:114](pg17.local)
  * [mssql2019, ip:117](mssql2019.local)
  * [mssql2022, ip:118](mssql2022.local)
  * [mssql2025, ip:119](mssql2025.local)

## Backups

### [Synology](./1topics/synology.md)

* k3s-ha [Velero](https://velero.io/docs/v1.16/backup-reference/)
  * `velero schedule create nightly-schedule --schedule="0 3 * * *"` every night at 3 am
  * `velero backup create --from-schedule nightly-schedule`
  * `velero backup get`, `velero backup describe nightly-schedule-20250728223504`, `velero backup logs nightly-schedule-20250728223504`
* TODO where backup?
* Synology, office.local:5100
  * Backup my dev PC
  * Backup my desktop PC
* Synology, backup2.local:5100


Git configuration:
`git config --global core.symlinks true` - no need

## TODO

[Learn GO and kubernetes](https://github.com/derailed/k9s)

[client-go](https://github.com/kubernetes/client-go)

[Officially-supported Kubernetes client libraries](https://kubernetes.io/docs/reference/using-api/client-libraries/)

[Kubernetes C# Client](https://github.com/kubernetes-client/csharp)

[Csharp terminal](https://github.com/gui-cs/Terminal.Gui)

## Tools

[Text-based desktop environment](https://github.com/directvt/vtm)

## Windows

https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-iot-enterprise-ltsc

## Hardware

Reboot router

* [Keep Connect](https://www.amazon.ca/Keep-Connect-Connectivity-Required-Necessary/dp/B07MCRQPCS/ref=sr_1_1_sspa?crid=281LMDENQNJXK&dib=eyJ2IjoiMSJ9.9O9tMToZfUQwJ6PdC53yCq4ZCaHNQpwzqYkyZCcFdlKkWnZq-3je3NY0mvvwLbxmDCBXoRkJJZicgpH-m2JMUA.kOB4R_4v84qNYAcAGPF6NLmzDn8TDlU61pOdrIhMtkI&dib_tag=se&keywords=keep+connect+router+rebooter&qid=1739460173&sprefix=keep+connect%2Caps%2C170&sr=8-1-spons&sp_csd=d2lkZ2V0TmFtZT1zcF9hdGY&psc=1)
* [Keep Connect](https://www.amazon.ca/Keep-Connect-Device-Automatic-Rebooter/dp/B0C6YCQ2ZV/ref=sr_1_3?crid=281LMDENQNJXK&dib=eyJ2IjoiMSJ9.9O9tMToZfUQwJ6PdC53yCq4ZCaHNQpwzqYkyZCcFdlKkWnZq-3je3NY0mvvwLbxmfUhxAzr_qCkC950HG4IWLNiQndeDLu655_YyJiWI2MA.qp9wn35q-pvXBImJi3PhJ6S_AXe1DXsKjUtdrenOfP8&dib_tag=se&keywords=keep+connect+router+rebooter&qid=1739460173&sprefix=keep+connect%2Caps%2C170&sr=8-3)

[Power splitter](https://www.amazon.ca/Cablelera-Power-Extension-Splitter-ZWACPQAG-14/dp/B00FRODUR4/ref=pd_bxgy_d_sccl_1/142-3045299-6895447?pd_rd_w=QeKgu&content-id=amzn1.sym.ceb81f1a-b020-4494-9533-0636b1bb08da&pf_rd_p=ceb81f1a-b020-4494-9533-0636b1bb08da&pf_rd_r=NE3BG6T0PDANKCY643KR&pd_rd_wg=Gyyms&pd_rd_r=d5ff476f-4f28-49d5-ac3c-658925dbf320&pd_rd_i=B00FRODUR4&th=1)

[MINISFORUM BD795i SE Mini ITX Motherboard, AMD Ryzen 9 7945HX, 16 C/32 T,Up to 5.2 GHz,PCIe 5.0 x16 Slot, Dual PCIe4.0 M.2 Support, DDR5,8K Triple Output with HDMI/DP/USB-C, RJ45 2.5G, USB 3.2 Gen 2](https://www.amazon.ca/MINISFORUM-BD795i-SE-Motherboard-PCIe4-0/dp/B0DGTSCQSY/ref=sr_1_1?crid=JSP7L12CI00R&dib=eyJ2IjoiMSJ9.e3WGLDog7JewWrENmXmwQmPSYNBVe0xPleJxQY7pQX1eVwh-7Ls0QZkb9nncliOv5X0DA2pEMvyyaT-bFSpFGQ1rnYSm78TBr2adKD_Z0sSTiea48Xw6c31TWAjqCbJvrYfY8KSo4SYr-9oPx0WSho1HBHr-0GLBbV3puFykPrGvVmMjuf9_7DF4bx9_6rPF9aeFgoH1tHyUrY9WZl8YYYzWZXnjwFY4vjEDPOHfTtcZSPxEpMohsKjSaIgtEnLBSj-2VGcXSLzEMCRRFjhKKhM8wpgT6gcT5DPNgkT65gpb4wroSDTbBdhFJGzowEznKlGf7tv21Mjr1zTq5X-ysMsgU7gr2Q2BlnOm3o7QXQ6HgihprFBG4QhP5UNowaS8x3faZcnJm1xuaNNmoN1-xzNuwoNAiskZJJ17fy9nrXCINSTBb31RBFcAGGqP7EzK.Sd0cimMC5cBUfBkhaV_s_LqgNZp9xtLNRfp9rvVhjQ0&dib_tag=se&keywords=minisforum+motherboard&qid=1739462732&sprefix=minisforum+mother%2Caps%2C119&sr=8-1)

## Universal USB

* [Medicat](https://github.com/mon5termatt/medicat_installer)
* [Medicat USB - FIX Any Computer Problem with this IT Toolkit (Full GUIDE)](https://www.youtube.com/watch?v=ktft9yz7HMc)
* [The All-In-One USB Tool | Medicat](https://www.youtube.com/watch?v=627oSs_H1E0)
* [Medicat USB - all in one usb bootable tool for IT Troubleshooting](https://www.youtube.com/watch?v=Af8Y-weJnVA&t=209s)

Additional ISO



## Remote Desktop

* [Your Remote Desktop SUCKS!! Try this instead (FREE + Open Source)](https://www.youtube.com/watch?v=EXL8mMUXs88)
* [Pricing of our self-hosting solutions](https://rustdesk.com/pricing/?lang=en)