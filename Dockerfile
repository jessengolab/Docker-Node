FROM python:2.7.15
USER root
# get the software packages from our Ubuntu repositories (Artifactory)
# that will allow us to build source packages. The nvm script will leverage these tools to build the necessary components 
RUN apt-get update --fix-missing && \
    apt-get install -y curl && \
    apt-get install -y build-essential libssl-dev && \
    apt-get install -y apt-utils && \
    apt-get upgrade -y
# Install nvm with node and npm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 11.6.0
# install libsass
RUN git clone https://github.com/sass/sassc && cd sassc && \
    git clone https://github.com/sass/libsass && \
    SASS_LIBSASS_PATH=/sassc/libsass make && \
    mv bin/sassc /usr/bin/sassc && \
    cd ../ && rm -rf /sassc
ENV SASS_BINARY_PATH=/usr/lib/node_modules/node-sass/build/Release/binding.node
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.30.1/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    # This version will be automatically selected when a new session spawns. 
    && nvm install $NODE_VERSION \
    # You can also reference it by the alias like this and change https://registry.npmjs.org to artifactory registry:
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    # created node-sass binary
    && git clone --recursive https://github.com/sass/node-sass.git \
    && cd node-sass \ 
    && git submodule update --init --recursive \
    && npm install \
    && node scripts/build -f \
    && cd ../ && rm -rf node-sass \
    && npm install -g express       

# RUN export PATH=/sbin:PATH
ENV NODE_PATH $NVM_DIR/$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/$NODE_VERSION/sbin::$PATH

# add binary path of node-sass to .npmrc
RUN touch $HOME/.npmrc && echo "sass_binary_cache=${SASS_BINARY_PATH}" >> $HOME/.npmrc

ENV SKIP_SASS_BINARY_DOWNLOAD_FOR_CI true
ENV SKIP_NODE_SASS_TESTS true
