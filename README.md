# 新概念英语 · 全四册

[在线学习：nce.chenzhuo.space:2474](https://nce.chenzhuo.space:2474)

适合在电脑和手机上使用的《新概念英语》点读站。这个自托管版本去掉了广告、推广和统计脚本，保留四册课文、音频、字幕和学习功能。

| 册次 | 课本 | 学习方向 |
| --- | --- | --- |
| 第一册 | First Things First | 日常对话、发音和基础句型 |
| 第二册 | Practice and Progress | 短篇故事、时态和表达 |
| 第三册 | Developing Skills | 长句理解、阅读和复述 |
| 第四册 | Fluency in English | 进阶阅读和复杂表达 |

## 怎么使用

- 点击课文中的句子即可点读；有双语字幕时可切换「中英」「英文」「中文」。
- 首次打开课文默认选中「连续播放」「1.2×」「中英」，不会自动播放。手动选择的播放模式、倍速和字幕偏好保存在当前浏览器。
- 「连续播放」播完本课即停止；旁边的「整课循环」播完停约 1.2 秒，再从头播放同一课。
- 「单句循环」反复播放当前句；「A-B 循环」显示两个设点按钮，可以选句设置区间起止点；「单次播放」下可以开启听写。
- 手机上的播放键、进度条和时间同排。点播放器上方的小箭头可以收起，底部只留展开箭头；收起不会打断播放，页面会记住收放状态。
- 首页可从播放历史继续学习，也可以通过「自定义设置」添加自己的课本。

## 本地运行

在项目目录运行 Python 3 静态服务器，不需要 Docker：

```bash
python3 http_server.py
```

打开 [本机地址](http://127.0.0.1:8082)。服务默认只监听本机。要在同一局域网用手机测试，可在可信网络中用 `NCE_BIND_IP=0.0.0.0 python3 http_server.py` 启动，再从手机打开 `http://<Mac 的局域网 IP>:8082`。端口冲突时修改 [http_server.py](http_server.py) 中的 `PORT`。

### 添加自定义课本

例如，将 `lesson1.mp3` 和 `lesson1.lrc` 放入项目下的 `custom/` 目录，从本地首页打开「自定义设置」，填写并保存：

```json
{
  "我的课程": [
    {
      "title": "第一课",
      "filename": "custom/lesson1.mp3",
      "lrc": "custom/lesson1.lrc"
    }
  ]
}
```

音频和字幕同目录且同名时，可以省略 `lrc`。在线 HTTPS 站点应使用同站资源或浏览器可访问的 HTTPS 资源；跨站字幕服务器需要允许跨域读取。

## 添加到 iPhone 主屏幕

用 Safari 打开 [在线学习首页](https://nce.chenzhuo.space:2474)，选择「分享 → 添加到主屏幕」。如果看到「作为网页 App 打开」，请保持开启。添加后，从主屏幕上的黄绿 NCE 图标进入，不会显示 Safari 的地址栏和工具栏。如果仍显示旧的「新」字图标，可移除旧入口后重新添加。

主屏幕入口不提供离线播放，音频和字幕仍需连接服务。

## Docker Hub 与 UGOS Pro 部署

镜像只包含网页程序和静态资源。`NCE1` 到 `NCE4` 通过 Compose 只读挂载，更新镜像不需要重新上传课程文件。UGOS Pro 从仓库拉镜像，不在 NAS 上构建。

1. **构建并推送镜像。** 在 Mac 上登录 Docker Hub，为 DXP4800 Plus 构建 `linux/amd64` 镜像：

   ```bash
   docker login
   docker buildx build --platform linux/amd64 \
     --tag docker.io/cwwen/nce-study:latest --push .
   ```

   自行发布时，把镜像名换成自己的仓库，并同步修改 Compose 中的 `image`。

2. **创建或更新 Compose 项目。** 在 UGOS Pro 的 Docker 项目界面使用 [compose.yaml](compose.yaml)，检查 `volumes` 左侧是否指向实际的课程目录。示例使用 `/volume3/docker/nce-study/NCE1` 至 `NCE4`。已有项目更新时，先让 UGOS 拉取新版镜像，再重新部署以重建容器；仅启动旧容器不会应用新镜像或新配置。

3. **验证课程资源。** 在局域网打开 `http://NAS_IP:15626`，进入第一册第一课，确认字幕加载且音频可播放。如果端口冲突，只修改端口映射左侧的 `15626`。需要对外访问时，再将 HTTPS 反向代理指向该局域网地址。

### 课名正常，但没有字幕和音频

课名来自镜像内的 `static/data.json`，不代表课程挂载正常。优先直连 NAS，查看 Docker 项目日志中的 `.mp3` 和 `.lrc` 请求：

- **`403` / `Permission denied`：** 检查容器的运行用户、Nginx worker 用户及挂载目录权限。示例 Compose 使用 `user: "0:0"` 并修改 Nginx 配置，让 worker 在容器内以 root 读取 UGOS 课程目录；课程挂载仍是只读。仅移除或修改 Compose 的 `user` 不会给普通 Nginx worker 授予课程读取权限。
- **`404` / `No such file or directory`：** 检查挂载路径和文件名。第一课的 `001&002－Excuse Me.mp3` 和同名 `.lrc` 应直接位于 `NCE1`，不要再套一层目录。
- **局域网可用、外部域名不可用：** 检查反向代理的目标地址，并确认访问时请求确实到达 NAS。

如需避免让 Nginx worker 以 root 运行，可以用 NAS ACL 给镜像内的 `nginx` 用户授予课程目录的遍历权限和音频、字幕的读取权限。先核对该用户的实际 UID，确认权限后移除 Compose 中的 `user` 和改写 Nginx 配置的 `command`，重新部署并验证第一课。

## 来源与许可

- 本项目基于 [hoothin/NCE](https://github.com/hoothin/NCE)，原始项目为 [iChochy/NCE](https://github.com/iChochy/NCE)。
- 代码采用 MIT 许可证，原有版权声明见 [LICENSE](LICENSE)。
- 课程音频来源：[tangx/New-Concept-English](https://github.com/tangx/New-Concept-English)。教材和音频不属于代码的 MIT 授权范围，请用于个人学习并尊重原资源的版权。
