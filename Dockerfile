FROM ruby:2.4

WORKDIR /code

# for ssh
# https://docs.docker.com/engine/examples/running_ssh_service/
ENV NOTVISIBLE "in users profile"
EXPOSE 22

ADD container_files /container_files

# Install base .bashrc aliases
# Added colors to PS1
RUN echo \
  && apt-get update && apt-get -y install rlwrap sqlite3 \
  && touch /root/.bash_history \
#  && apt-get install -y net-tools \
#  && gem uninstall bundler \
#  && gem install bundler \
  # keep history unique \
  && echo 'export HISTCONTROL=ignoreboth:erasedups' >> /root/.bashrc \
  && curl -Ls https://gist.github.com/andkirby/0e2982bee321aa611bc66385dee5f399/raw/bashrc_init_install.sh | bash \
  && curl -Ls https://gist.github.com/andkirby/389f18642fc08d1b0711d17978445f2b/raw/bashrc_ps1_install.sh | bash \
  # install SSH
  && apt-get install -y openssh-server \
  && mkdir /var/run/sshd \
  && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
  && echo "export VISIBLE=now" >> /etc/profile \
  && touch /container_files/authorized_keys \
  && cat /container_files/authorized_keys > /root/authorized_keys \
  && cat /container_files/id_rsa.pub >> /root/authorized_keys \

