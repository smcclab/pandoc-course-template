FROM pandoc/latex:3.9

# Install Python, Make, Bash, Git, and other utilities
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-yaml \
    make \
    bash \
    git \
    wget \
    curl

# Install required LaTeX packages
RUN tlmgr update --self && \
    tlmgr install \
        libertine \
        sourcecodepro \
        ly1 \
        sectsty \
        lastpage \
        hanging \
        beamer \
        beamertheme-metropolis \
        pgfopts \
        beamercolorthemeowl \
        noto \
        noto-emoji

# Install Dart Sass (musl/Alpine build)
RUN wget -O /tmp/dart-sass.tar.gz \
        https://github.com/sass/dart-sass/releases/download/1.89.2/dart-sass-1.89.2-linux-x64-musl.tar.gz && \
    tar -xzf /tmp/dart-sass.tar.gz -C /usr/local/ && \
    ln -s /usr/local/dart-sass/sass /usr/local/bin/sass && \
    rm /tmp/dart-sass.tar.gz

# Set bash as the default shell
SHELL ["/bin/bash", "-c"]
