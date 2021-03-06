FROM gmaslowski/jdk:latest as builder
ENV DIR=/root/android
WORKDIR $DIR
RUN ls && \
# sed -i 's/http:\/\/dl-cdn.alpinelinux.org/https:\/\/mirrors.aliyun.com/g' /etc/apk/repositories && \
apk update && \
apk add --no-cache ca-certificates && \
apk add git && \
git clone https://github.com/nelenkov/android-backup-extractor.git && \
cd android-backup-extractor && \
./gradlew

FROM openjdk:8u265-jre-slim-buster as builder2
ENV DIR=/root/android
WORKDIR $DIR
COPY ./decrypt.py $DIR
RUN ls && \
# sed -i "s@http://deb.debian.org@https://mirrors.ustc.edu.cn@g" /etc/apt/sources.list && \
apt-get update && \
apt-get install -y --fix-missing python python-dev libssl-dev gcc python-pip && \
# -i https://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com/pypi/simple/
pip install pysqlcipher --install-option="--bundled" && \
# -i https://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com/pypi/simple/
# pyinstaller最新版不支持python2.7了，需要指定版本
pip install pyinstaller==3.6
# 上边是环境配置，使用一条RUN指令，下方是编译程序，使用另一条RUN指令，可以防止只使用一条RUN指令导致每次更改程序都需要重新配置环境，方便测试
RUN pyinstaller -F --distpath ./ decrypt.py

FROM openjdk:8u265-jre-slim-buster as builder3
ENV DIR=/root/android
WORKDIR $DIR
COPY ./process.py $DIR
RUN ls && \
# sed -i "s@http://deb.debian.org@https://mirrors.ustc.edu.cn@g" /etc/apt/sources.list && \
apt-get update && \
apt-get install -y --fix-missing python3 python3-pip && \
# -i https://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com/pypi/simple/
python3 -m pip install pyinstaller javaobj-py3 lxml
# 上边是环境配置，使用一条RUN指令，下方是编译程序，使用另一条RUN指令，可以防止只使用一条RUN指令导致每次更改程序都需要重新配置环境，方便测试
RUN pyinstaller -F --distpath ./ process.py

FROM openjdk:8u265-jre-slim-buster as run
ENV DIR=/root/android
WORKDIR $DIR
COPY --from=0 /root/android/android-backup-extractor/build/libs/abe-all.jar $DIR
COPY --from=1 /root/android/decrypt $DIR
COPY --from=2 /root/android/process $DIR
RUN ls && \
sed -i "s@http://deb.debian.org@http://mirrors.aliyun.com@g" /etc/apt/sources.list
CMD ./process