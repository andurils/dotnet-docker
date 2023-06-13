# C# started guides

## 1.Build images

### Sample application 示例应用程序

使用 .NET 从模板创建一个简单的应用程序

```bash
mkdir dotnet-docker
cd dotnet-docker
dotnet new webapp -n myWebApp -o src --no-https
```

启动应用程序并确保它正常运行。打开终端并导航到 `src` 目录并使用 `dotnet run` 命令。

```bash
cd /path/to/src
dotnet run --urls http://localhost:5000
```

打开 Web 浏览器并根据输出中的 URL `http://localhost:5000` 访问应用程序。在终端窗口中按 `Ctrl+C` 停止应用程序。

### Create a Dockerfile 创建 Dockerfile

在 `dotnet-docker` 目录中，创建一个名为 `.Dockerfile` 的文件。

```Dockerfile
# 多阶段构建并定义用于构建应用程序的阶段 ,使用 as 定义 build-env 阶段
FROM mcr.microsoft.com/dotnet/sdk:6.0 as build-env

# 每个命令都会创建一个新的容器层
# 指定此阶段的工作目录
WORKDIR /src
# 复制 csproj 文件，
COPY src/*.csproj .
# 运行 ​​ dotnet restore
RUN dotnet restore
# 将文件从本地计算机上的 src 目录复制到镜像中
COPY src .
# 运行 dotnet publish 命令来构建项目
RUN dotnet publish -c Release -o /publish


# 指定用于运行应用程序的映像，并将其定义为 runtime 阶段
FROM mcr.microsoft.com/dotnet/aspnet:6.0 as runtime
# 指定此阶段的工作目录
WORKDIR /publish
# 将 /publish 目录从 build-env 阶段复制到运行时映像中。
COPY --from=build-env /publish .
# 暴露端口 80
EXPOSE 80
# 使用 ENTRYPOINT 命令执行  在容器内执行时运行命令
ENTRYPOINT ["dotnet", "myWebApp.dll"]
```

### .dockerignore file

为了使您的构建内容尽可能小，请将 `.dockerignore` 文件添加到您的 `dotnet-docker` 文件夹并将以下内容复制到其中。

```
**/bin/
**/obj/
```

### Build an image

使用 docker build 命令构建我们的镜像

构建命令可选地使用 --tag 标志。该标签用于设置图像的名称和格式为 name:tag 的可选标签。我们暂时不使用可选的 tag 以帮助简化事情。如果您不传递标签，Docker 将使用“latest”作为其默认标签。

```bash
cd /path/to/dotnet-docker
docker build --tag dotnet-docker .
```

查看本地镜像

```bash
docker images
```

### Tag images

该命令为镜像创建一个新标签。它不会创建新镜像。标签指向同一张镜像，只是引用镜像的另一种方式。

```bash
docker tag dotnet-docker:latest dotnet-docker:v1.0.0

# 删除刚刚创建的标签
docker rmi dotnet-docker:v1.0.0 
```

## 2.Run your image as a container

### Overview

使用 docker run 命令运行镜像，使用 `-p` 标志将容器的端口映射到主机上的端口。

```bash
docker run -p 5000:80  dotnet-docker
```

要为我们的容器发布端口，我们将在 docker run 命令上使用 --publish 标志（简称 -p ）。 --publish 命令的格式为 [host port]:[container port] 。因此，如果我们想将容器内的端口 80 暴露给容器外的端口 5000，我们会将 5000:80 传递给 --publish 标志。使用以下命令运行容器：

访问 <http://localhost:5000/> 即可

### Run in detached mode

Docker 可以在分离模式或后台运行您的容器。为此，我们可以简称为 --detach 或 -d 。 Docker 像以前一样启动您的容器，但这次将从容器“分离”并返回到终端提示符

```bash
docker run -d -p 5000:80 dotnet-docker
ce02b3179f0f10085db9edfccd731101868f58631bdf918ca490ff6fd223a93b
```

不必连接到容器 Docker 在后台启动我们的容器，并在终端上打印容器 ID

可以运行 docker ps 命令。就像在 Linux 上查看机器上的进程列表一样

```bash
docker ps
```

运行 docker stop 命令来停止容器。您需要传递容器的名称，也可以使用容器 ID。

### Stop, start, and name containers

您可以启动、停止和重新启动 Docker 容器。当我们停止一个容器的时候，它并没有被移除，而是状态变成了stopped，停止了容器内部的进程。当我们在上一个模块中运行 docker ps 命令时，默认输出仅显示正在运行的容器。当我们通过 --all 或 -a 时，我们会看到我们机器上的所有容器，无论它们的启动或停止状态如何。

让我们解决随机命名问题。标准做法是为您的容器命名，原因很简单，这样更容易识别容器中运行的内容以及它关联的应用程序或服务。

```
docker run -d -p 5000:80 --name dotnet-app dotnet-docker 
```

要删除容器，只需运行传递容器名称的 docker rm 命令。您可以使用单个命令将多个容器名称传递给该命令。同样，将以下命令中的容器名称替换为系统中的容器名称。

```
docker stop dotnet-app
docker rm dotnet-app
```

## 3.Use containers for development

### Run a database in a container
首先，我们来看看在容器中运行数据库，以及我们如何使用卷和网络来持久化我们的数据并允许我们的应用程序与数据库对话。然后，我们将把所有内容整合到一个 Compose 文件中，该文件允许我们使用一条命令设置和运行本地开发环境

 create a volume that Docker can manage to store our persistent data. Let’s use the managed volumes feature that Docker provides instead of using bind mounts.
 创建一个 Docker 可以管理的卷来存储我们的持久数据。让我们使用 Docker 提供的托管卷功能，而不是使用绑定挂载。

# 创建数据卷
docker volume create postgres-data


现在我们将创建一个网络，我们的应用程序和数据库将使用该网络相互通信。该网络称为用户定义的桥接网络，并为我们提供了一个很好的 DNS 查找服务，我们可以在创建连接字符串时使用它。
docker network create postgres-net

现在我们可以在容器中运行 PostgreSQL 并附加到我们上面创建的卷和网络。 Docker 从 Hub 拉取镜像并在本地为您运行。在以下命令中，选项 -v 用于启动带有该卷的容器。
docker run --rm -d -v postgres-data:/var/lib/postgresql/data \
  --network postgres-net \
  --name db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=example \
  postgres

  docker run --rm -d -v postgres-data:/var/lib/postgresql/data   --network postgres-net   --name db   -e POSTGRES_USER=postgres   -e POSTGRES_PASSWORD=example   postgres


  确保我们的 PostgreSQL 数据库正在运行并且我们可以连接到它。使用以下命令连接到容器内正在运行的 PostgreSQL 数据库
通过将 psql 命令传递给 db 容器来登录到PostgreSQL 数据库。
  docker exec -ti db psql -U postgres 

  按 CTRL-D 退出交互式终端。


  ### Update the application to connect to the database
