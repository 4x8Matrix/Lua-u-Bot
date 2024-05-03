FROM rust:1.78-slim-bookworm

WORKDIR /usr/src/app
COPY . .

RUN apt-get update -qq \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \

	libssl-dev g++ \

	&& cargo install lune --locked --no-track -q --version ~0.8

ENTRYPOINT ["lune", "run", "Source"]
