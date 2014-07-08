FROM                    phusion/baseimage
MAINTAINER              Ana Nelson <ana@ananelson.com>

### "localedef"
RUN localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 || :

### "squid-deb-proxy"
# Use squid deb proxy (if available on host OS) as per https://gist.github.com/dergachev/8441335
# Modified by @ananelson to detect squid on host OS and only enable itself if found.
ENV HOST_IP_FILE /tmp/host-ip.txt
RUN /sbin/ip route | awk '/default/ { print "http://"$3":8000" }' > $HOST_IP_FILE
RUN HOST_IP=`cat $HOST_IP_FILE` && curl -s $HOST_IP | grep squid && echo "found squid" && echo "Acquire::http::Proxy \"$HOST_IP\";" > /etc/apt/apt.conf.d/30proxy || echo "no squid"

### "apt-defaults"
RUN echo "APT::Get::Assume-Yes true;" >> /etc/apt/apt.conf.d/80custom
RUN echo "APT::Get::Quiet true;" >> /etc/apt/apt.conf.d/80custom

### "oracle-java-ppa"
RUN add-apt-repository ppa:webupd8team/java

### "update"
RUN apt-get update

### "utils"
RUN apt-get install build-essential
RUN apt-get install adduser
RUN apt-get install curl
RUN apt-get install sudo

### "nice-things"
RUN apt-get install ack-grep
RUN apt-get install strace
RUN apt-get install vim
RUN apt-get install git
RUN apt-get install tree
RUN apt-get install wget
RUN apt-get install unzip
RUN apt-get install rsync

### "oracle-java"
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
RUN apt-get install oracle-java7-installer

### "ant"
RUN apt-get install ant

# TODO Finish pig and datafu installs

### "pig"
WORKDIR /tmp
RUN git clone https://github.com/apache/pig.git
WORKDIR /tmp/pig
RUN git fetch
RUN git checkout branch-0.13
RUN ant mvn-install 
RUN ant piggybank

### "datafu"
WORKDIR /tmp
RUN git clone git://git.apache.org/incubator-datafu.git
WORKDIR /tmp/incubator-datafu
RUN ant jar

### "python-dexy"
RUN apt-get install python-dev
RUN apt-get install python-pip
RUN pip install dexy

### "create-user"
RUN useradd -m -p $(perl -e'print crypt("foobarbaz", "aa")') repro
RUN adduser repro sudo

### "activate-user"
ENV HOME /home/repro
USER repro
WORKDIR /home/repro
