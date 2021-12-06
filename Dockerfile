FROM debian:stable

ARG GHC_VERSION=8.10.7

ENV USERNAME=lambda \
    USER_UID=2001 \
    USER_GID=2001 \
    DEBIAN_FRONTEND=noninteractive \
    GHC_VERSION=$GHC_VERSION

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    git curl xz-utils gcc make libtinfo5 libgmp-dev\
    zlib1g-dev bash sudo procps lsb-release ca-certificates\
    build-essential libffi-dev libgmp-dev libgmp10 libncurses-dev\ 
    libncurses5 libtinfo5 libicu-dev libncurses-dev z3 locales locales-all

# UTF-8 is not generated by default 
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LC_ALL en_US.UTF-8 
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd -ms /bin/bash -K MAIL_DIR=/dev/null --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

USER ${USER_UID}:${USER_GID}
WORKDIR /home/${USERNAME}
ENV PATH="/home/${USERNAME}/.local/bin:/home/${USERNAME}/.cabal/bin:/home/${USERNAME}/.ghcup/bin:$PATH"

RUN echo "export PATH=$PATH" >> /home/$USERNAME/.profile

ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=yes \
    BOOTSTRAP_HASKELL_NO_UPGRADE=yes \
    BOOTSTRAP_HASKELL_INSTALL_HLS=yes \
    BOOTSTRAP_HASKELL_GHC_VERSION=$GHC_VERSION

# Install ghcup
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# Install the specified GHC_VERSION. A No-op if already installed during bootstrap.
RUN ghcup install ghc $GHC_VERSION

# Set the GHC version.
RUN ghcup set ghc $GHC_VERSION

# Install cabal-iinstall
RUN ghcup install cabal

# Install global packages.
RUN cabal install --global --lib QuickCheck ansi-terminal random threepenny-gui hlint aeson
RUN cabal install hlint


ENV DEBIAN_FRONTEND=dialog

ENTRYPOINT ["/bin/bash"]
