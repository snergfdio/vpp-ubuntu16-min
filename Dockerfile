FROM snergster/vpp-ubuntu16
MAINTAINER Ed Kern <ejk@cisco.com>
LABEL Description="VPP ubuntu 16 baseline" 
LABEL Vendor="cisco.com" 
LABEL Version="3.1"


# Setup the environment
ENV DEBIAN_FRONTEND=noninteractive
ENV MAKE_PARALLEL_FLAGS -j 4
ENV DOCKER_TEST=True
ENV VPP_ZOMBIE_NOCHECK=1
ENV DPDK_DOWNLOAD_DIR=/w/Downloads
ENV VPP_PYTHON_PREFIX=/var/cache/vpp/python

ADD files/99fd.io.list /etc/apt/sources.list.d/99fd.io.list
ADD files/sshconfig /root/.ssh/config
ADD files/wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

RUN apt update && apt install -y -qq \
		software-properties-common \
        apt-transport-https \
        && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository -y ppa:openjdk-r/ppa

RUN apt update && apt install -y vpp-dpdk-dev vpp-dpdk-dkms \
		openssh-server \
		bash \
		bash-completion \
		curl \
        default-jre-headless \
        chrpath \
        nasm \
        unzip \
        xz-utils \
        puppet \
        git \
        git-review \
        libxml-xpath-perl \
        make \
        wget \
        openjdk-8-jdk \
        jq \
        libffi-dev \
	    python-all \
	    autoconf \
        automake \
        autotools-dev \
        bison \
        ccache \
        cscope \
        m4 \
        pkg-config \
        po-debconf \
        python-dev \
        python-virtualenv \
        python2.7-dev \
        locales \
        llvm \
        clang \
        clang-format \
        clang-5.0 \
        libboost-all-dev \
        ruby-dev \
        zile \
        default-jdk-headless \
        python-ply \
        iperf3 \
        libibverbs-dev \
        python-markupsafe \
        python-jinja2 \
        python-pyparsing \
        doxygen \
        graphviz \
        && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd
RUN echo 'root:Csit1234' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EXPOSE 8080

RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-5.0 1000 && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-5.0 1000

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" 

# For the docs
RUN apt-get -q update && \
    apt-get install -y -qq \
        python-markupsafe \
        python-jinja2 \
        python-pyparsing \
        doxygen \
        graphviz \
        docker-ce \
        tzdata \
        locales \
        && rm -rf /var/lib/apt/lists/*

# Configure locales
RUN locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales

# Fix permissions
RUN chown root:syslog /var/log \
    && chmod 755 /etc/default

RUN mkdir -p /tmp/dumps /workspace /var/ccache && ln -s /var/ccache /tmp/ccache

ENV CCACHE_DIR=/var/ccache
ENV CCACHE_READONLY=true

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN gem install rake
RUN gem install package_cloud
RUN pip install six scapy==2.3.3 pyexpect subprocess32 cffi git+https://github.com/klement/py-lispnetworking@setup pycodestyle
#Below are requirements for csit
RUN pip install robotframework==2.9.2 paramiko==1.16.0 scp==0.10.2 ipaddress==1.0.16 interruptingcow==0.6 PyYAML==3.11 pykwalify==1.5.0 \
        enum34==1.1.2 requests==2.9.1 ecdsa==0.13 pycrypto==2.6.1 pypcap==1.1.5

RUN mkdir -p /var/cache/vpp/python
RUN mkdir -p /w/Downloads
RUN wget -O /w/Downloads/nasm-2.13.01.tar.xz http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/nasm-2.13.01.tar.xz
RUN wget -O /w/Downloads/dpdk-18.02.1.tar.xz http://fast.dpdk.org/rel/dpdk-18.02.1.tar.xz
#RUN wget -O /w/Downloads/dpdk-18.02.1.tar.xz http://dpdk.org/browse/dpdk-stable/snapshot/dpdk-stable-18.02.1.tar.xz
RUN wget -O /w/Downloads/dpdk-18.05.tar.xz http://fast.dpdk.org/rel/dpdk-18.05.tar.xz
#RUN wget -O /w/Downloads/dpdk-18.05.tar.xz http://dpdk.org/browse/dpdk/snapshot/dpdk-18.05.tar.xz
RUN wget -O /w/Downloads/dpdk-17.11.tar.xz http://fast.dpdk.org/rel/dpdk-17.11.tar.xz
RUN wget -O /w/Downloads/v0.47.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.47.tar.gz
RUN wget -O /w/Downloads/v0.48.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.48.tar.gz
RUN wget -O /w/Downloads/v0.49.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.49.tar.gz

#RUN mkdir -p /w/dpdk && cd /w/dpdk; apt-get download vpp-dpdk-dkms
RUN mkdir -p /w/workspace/vpp-test-poc-verify-master-ubuntu1604 && mkdir -p /home/jenkins

RUN git clone https://gerrit.fd.io/r/vpp /w/workspace/vpp-test-poc-verify-master-ubuntu1604 && cd /w/workspace/vpp-test-poc-verify-master-ubuntu1604; make UNATTENDED=yes install-dep && make UNATTENDED=yes test-dep && rm -rf /w/workspace/vpp-test-poc-verify-master-ubuntu1604
RUN mkdir -p /run/shm && rm -f /var/cache/vpp/python/papi-install.done && rm -f /var/cache/vpp/python/virtualenv/lib/python2.7/site-packages/vpp_papi-*-py2.7.egg
VOLUME /var/lib/docker
RUN echo 'Port 6022' >>/etc/ssh/sshd_config

