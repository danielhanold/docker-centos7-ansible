# Based on https://github.com/geerlingguy/docker-centos7-ansible/blob/python3/Dockerfile
FROM centos:7
ENV container=docker
ENV ANSIBLE_VERSION "2.9.27"
ENV PYTHON_VERSION "3.7.9"

# Install suggested Python build dependencies.
# https://github.com/pyenv/pyenv/wiki#suggested-build-environment
RUN yum -y install \
  gcc \
  zlib-devel \
  bzip2 \
  bzip2-devel \
  readline-devel \
  sqlite \
  sqlite-devel \
  openssl-devel \
  tk-devel \
  libffi-devel \
  xz-devel \
  wget \
  make

# Install alternative version of Python.
# https://vinodpandey.com/how-to-install-python3-on-centos-7/
RUN cd /tmp/ && \
  wget "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" && \
  tar xzf "Python-${PYTHON_VERSION}.tgz" && \
  cd "Python-${PYTHON_VERSION}" && \
  ./configure --enable-optimizations && \
  make altinstall && \
  ln -sfn /usr/local/bin/python3.7 /usr/bin/python3.7 && \
  ln -sfn /usr/local/bin/pip3.7 /usr/bin/pip3.7

# Install systemd -- See https://hub.docker.com/_/centos/
RUN yum -y update; yum clean all; \
  (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
  rm -f /lib/systemd/system/multi-user.target.wants/*;\
  rm -f /etc/systemd/system/*.wants/*;\
  rm -f /lib/systemd/system/local-fs.target.wants/*; \
  rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
  rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
  rm -f /lib/systemd/system/basic.target.wants/*;\
  rm -f /lib/systemd/system/anaconda.target.wants/*;

# Install requirements.
RUN yum makecache fast \
  && yum -y install deltarpm epel-release initscripts \
  && yum -y update \
  && yum -y install \
  sudo \
  which \
  && yum clean all

# Fix LC warnings.
# https://github.com/CentOS/sig-cloud-instance-images/issues/71
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# Install Ansible and dependencies via Pip.
# https://snarky.ca/why-you-should-use-python-m-pip/
RUN python3.7 -m pip install "ansible==${ANSIBLE_VERSION}" && \
  python3.7 -m pip install pycrypto

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts

# Create directory for Ansible playbooks/
RUN mkdir -p /root/dev
WORKDIR /root/dev

VOLUME ["/sys/fs/cgroup"]
CMD ["/usr/lib/systemd/systemd"]
