FROM ubuntu:latest

WORKDIR /usr/src/app
COPY . .

RUN apt update && \
        apt install curl gpg -y && \
        curl https://id.devcomp.xyz/hi@devcomp.xyz/2.gpg | gpg --import && \
        sh -c "curl https://id.devcomp.xyz/hi@devcomp.xyz/2.gpg | gpg --dearmor > /usr/share/keyrings/lune-archive-keyring.gpg" && \
        echo "deb [signed-by=/usr/share/keyrings/lune-archive-keyring.gpg] https://repos.devcomp.xyz/ bookworm main" >> /etc/apt/sources.list && \
        apt update && \
        apt install lune -y

ENTRYPOINT ["lune", "run", "Source"]
