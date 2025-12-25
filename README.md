# filebrowser-quantum

<hr>

## 注意事项
* 1.密码至少10位数
* 3.普通用户保存的内容管理员可见
* 4.管理员添加新用户注意设置用户访问目录权限

## 安装
```shell
bash <(curl -Ls https://raw.githubusercontent.com/co2f2e/filebrowser-quantum/main/install.sh) 8088 admin
```
## 卸载
```shell
bash <(curl -Ls https://raw.githubusercontent.com/co2f2e/filebrowser-quantum/main/uninstall.sh)
```
## NGINX
```nginx
location ^~ / {
    proxy_pass http://127.0.0.1:8088;
    proxy_http_version 1.1;

    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    client_max_body_size 2G;
    proxy_buffering off;

    proxy_connect_timeout 600s;
    proxy_send_timeout 600s;
    proxy_read_timeout 600s;
    }
```
