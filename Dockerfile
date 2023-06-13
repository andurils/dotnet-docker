# 多阶段构建并定义用于构建应用程序的阶段 ,使用 as 定义 build-env 阶段
FROM mcr.microsoft.com/dotnet/sdk:7.0 as build-env

# 每个命令都会创建一个新的容器层
# 为源文件创建一个工作目录  基于工作目录的相对路径
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
FROM mcr.microsoft.com/dotnet/aspnet:7.0 as runtime
# 指定此阶段的工作目录
WORKDIR /publish
# 将 /publish 目录从 build-env 阶段复制到运行时映像中。
COPY --from=build-env /publish .
# 将端口 80 暴露给传入请求
EXPOSE 80
# 使用 ENTRYPOINT 命令执行  在容器内执行时运行命令
ENTRYPOINT ["dotnet", "myWebApp.dll"]