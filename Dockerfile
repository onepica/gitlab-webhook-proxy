FROM bitnami/ruby:latest

# Install base .bashrc aliases
# Added colors to PS1
RUN apt-get update -y \
  && touch /root/.bash_history
  && apt-get install -y net-tools \
  # keep history unique
  && echo 'export HISTCONTROL=ignoreboth:erasedups' >> /root/.bashrc \
  && curl -Ls https://gist.github.com/andkirby/0e2982bee321aa611bc66385dee5f399/raw/bashrc_init_install.sh | bash \
  && curl -Ls https://gist.github.com/andkirby/389f18642fc08d1b0711d17978445f2b/raw/bashrc_ps1_install.sh | bash

