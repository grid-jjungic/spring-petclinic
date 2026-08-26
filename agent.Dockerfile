FROM jenkins/inbound-agent:latest-jdk21

USER root

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	docker.io \
	git \
	&& rm -rf /var/lib/apt/lists/*

USER jenkins
