This docker compose file runs cp components on docker and it is configured to advertise the public ip of the ec2 instance where docker host is running so that client external to docker can produce and consume

[docker host]
> docker compose up -d

[local machine/mac]
> kcat -b <ec2-public-ip>:9092 -L
