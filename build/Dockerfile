FROM ubuntu:16.04
RUN apt-get update -y && apt-get install software-properties-common -y && add-apt-repository ppa:deadsnakes/ppa && apt-get update -y && apt-get upgrade -y
RUN apt-get install git-core -y && cd home && mkdir testGit && cd testGit && git init && git config --global user.name "devopsUser" && git config --global user.email "devops@email.com"
RUN apt-get install maven -y
RUN apt-get install openjdk-8-jdk -y
# RUN apt-get install nodejs -y && apt-get install npm -y
RUN mkdir /home/nodejsinstall && mkdir /home/pipinstall
COPY nodesource_setup.sh /home/nodejsinstall
RUN cd home/nodejsinstall && bash nodesource_setup.sh && apt-get install nodejs -y
RUN cd home/pipinstall && apt-get install python3.6 -y && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python get-pip.py
RUN mkdir /home/codefiles
CMD ["/bin/bash"]