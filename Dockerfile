FROM mcr.microsoft.com/devcontainers/go:1-1.21-bookworm as workspace

# install needed environment (with ubuntu packaging dependencies)

RUN export DEBIAN_FRONTEND=noninteractive && \
  # sed -i 's/# deb-src/deb-src/g' /etc/apt/sources.list && \
  # sed -i 's:archive.ubuntu.com:br.archive.ubuntu.com:g' /etc/apt/sources.list && \
  # cat /etc/apt/sources.list | grep -Ev 'proposed|backports|security' > /tmp/sources.list && \
  # mv /tmp/sources.list /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y sudo coreutils findutils && \
  apt-get install -y bash git curl rsync && \
  apt-get install -y make gcc && \
  apt-get install -y linux-headers-generic && \
  apt-get install -y libelf-dev && \
  apt-get install -y zlib1g-dev && \
  apt-get install -y build-essential devscripts ubuntu-dev-tools && \
  apt-get install -y debhelper dh-exec dpkg-dev pkg-config && \
  apt-get install -y software-properties-common

RUN export uid=$uid gid=$gid && \
  mkdir -p /tracee/tracee && \
  mkdir -p /home/tracee && \
  echo "tracee:x:${uid}:${gid}:Tracee,,,:/home/tracee:/bin/bash" >> /etc/passwd && \
  echo "tracee:x:${gid}:" >> /etc/group && \
  echo "tracee::99999:0:99999:7:::" >> /etc/shadow && \
  chown ${uid}:${gid} -R /home/tracee && \
  chown ${uid}:${gid} -R /tracee && \
  echo "export PS1=\"\u@\h[\w]$ \"" > /home/tracee/.bashrc && \
  echo "alias ls=\"ls --color\"" >> /home/tracee/.bashrc && \
  ln -s /home/tracee/.bashrc /home/tracee/.profile

# install clang

RUN curl -L -o /tmp/clang.tar.xz https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang+llvm-14.0.6-x86_64-linux-gnu-rhel-8.4.tar.xz && \
  tar -C /usr/local -xJf /tmp/clang.tar.xz && \
  mv "/usr/local/clang+llvm-14.0.6-x86_64-linux-gnu-rhel-8.4" /usr/local/clang && \
  echo "export PATH=/usr/local/clang/bin:$PATH" >> /home/tracee/.bashrc && \
  update-alternatives --remove-all cc || true && \
  update-alternatives --remove-all clang || true && \
  update-alternatives --remove-all clang++ || true && \
  update-alternatives --remove-all llc || true && \
  update-alternatives --remove-all lld || true && \
  update-alternatives --remove-all clangd || true && \
  update-alternatives --remove-all clang-format || true && \
  update-alternatives --remove-all llvm-strip || true && \
  update-alternatives --remove-all llvm-config || true && \
  update-alternatives --remove-all ld.lld || true && \
  update-alternatives --remove-all llvm-ar || true && \
  update-alternatives --remove-all llvm-nm || true && \
  update-alternatives --remove-all llvm-objcopy || true && \
  update-alternatives --remove-all llvm-objdump || true && \
  update-alternatives --remove-all llvm-readelf || true && \
  update-alternatives --remove-all opt || true && \
  update-alternatives --install /usr/bin/clang clang /usr/local/clang/bin/clang 140 \
  --slave /usr/bin/clang++ clang++ /usr/local/clang/bin/clang++ \
  --slave /usr/bin/clangd clangd /usr/local/clang/bin/clangd \
  --slave /usr/bin/clang-format clang-format /usr/local/clang/bin/clang-format \
  --slave /usr/bin/lld lld /usr/local/clang/bin/lld \
  --slave /usr/bin/llc llc /usr/local/clang/bin/llc \
  --slave /usr/bin/llvm-strip llvm-strip /usr/local/clang/bin/llvm-strip \
  --slave /usr/bin/llvm-config llvm-config /usr/local/clang/bin/llvm-config \
  --slave /usr/bin/ld.lld ld.lld /usr/local/clang/bin/ld.lld \
  --slave /usr/bin/llvm-ar llvm-ar /usr/local/clang/bin/llvm-ar \
  --slave /usr/bin/llvm-nm llvm-nm /usr/local/clang/bin/llvm-nm \
  --slave /usr/bin/llvm-objcopy llvm-objcopy /usr/local/clang/bin/llvm-objcopy \
  --slave /usr/bin/llvm-objdump llvm-objdump /usr/local/clang/bin/llvm-objdump \
  --slave /usr/bin/llvm-readelf llvm-readelf /usr/local/clang/bin/llvm-readelf \
  --slave /usr/bin/opt opt /usr/local/clang/bin/opt \
  --slave /usr/bin/cc cc /usr/local/clang/bin/clang


# extra tools for testing things
RUN apt-get install -y man bash-completion vim && \
  apt-get install -y iproute2 vlan bridge-utils net-tools && \
  apt-get install -y netcat-openbsd iputils-ping && \
  apt-get install -y wget lynx w3m && \
  apt-get install -y stress

# Install gh cli
RUN type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y) \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg  \
  && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y

# Install libbpf headers
RUN apt-get install -y libbpf-dev libbpf1
