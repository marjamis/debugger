FROM alpine:3.10.1

RUN apk add --no-cache openssh tcpdump curl mtr nmap nmap-nping bind-tools nginx jq 
  #apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ aws-cli
# Install aws-cli
RUN apk -Uuv add groff less python py-pip
RUN pip install awscli
RUN apk --purge -v del py-pip
RUN rm /var/cache/apk/*
ADD files/ /files/

# Installing/Configuring SSH for access
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa && \
  ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa && \
  ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa && \
  ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519 && \
  sed -i "s/#Port 22/Port 8022/" /etc/ssh/sshd_config && \
  mkdir /root/.ssh && \
# Configure some of the basics of nginx
  mkdir /run/nginx/ && \
  ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log && \
  ln -sf /files/nginx_default.conf /etc/nginx/conf.d/default.conf && \
  mkdir -p /usr/share/nginx/html && \
  echo "Hello World!!!" > /usr/share/nginx/html/index.html && \
# Configure the importing of all environment variables from pid 1 to make use of the ECS specific environment variables(Task Roles) for the awscli
  echo 'export $(strings /proc/1/environ)' > /root/.profile && \
# Changing the motd to remember the above configuration
  printf '\n\nNOTICE: export $(strings /proc/1/environ) is run on the ash shell profile which makes the aws cli work with Task Roles.\nc' > /etc/motd

COPY ./testing.pub /root/.ssh/authorized_keys

CMD [ "/files/entrypoint.sh" ]
