FROM debian:stable

ARG GHC_VERSION=8.10.4

ENV USERNAME=lambda \
    USER_UID=2001 \
    USER_GID=2001 \
    DEBIAN_FRONTEND=noninteractive \
    GHC_VERSION=$GHC_VERSION

RUN apt-get update
RUN apt-get install -y --no-install-recommends git curl xz-utils gcc make libtinfo5 libgmp-dev zlib1g-dev bash sudo procps lsb-release ca-certificates build-essential libffi-dev libgmp-dev libgmp10 libncurses-dev libncurses5 libtinfo5 libicu-dev libncurses-dev z3

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd -ms /bin/bash -K MAIL_DIR=/dev/null --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

USER ${USER_UID}:${USER_GID}
WORKDIR /home/${USERNAME}
ENV PATH="/home/${USERNAME}/.local/bin:/home/${USERNAME}/.cabal/bin:/home/${USERNAME}/.ghcup/bin:$PATH"

RUN echo "export PATH=$PATH" >> /home/$USERNAME/.profile

ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=yes \
    BOOTSTRAP_HASKELL_NO_UPGRADE=yes
    BOOTSTRAP_HASKELL_GHC_VERSION=$GHC_VERSION

# Install ghcup
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# Check if needed GHC_VERSION was already installed during bootstrap, otherwise - install it.
RUN echo "Checking, whether GHC($GHC_VERSION) is already installed" && \
    if ghcup list 2>&1 | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | grep -P "\xE2\x9C\x94\sghc\s+$GHC_VERSION\s+\w+" ; \
    then \
        echo "GHC $GHC_VERSION is already installed via ghcup." ; \
    else \
        echo "GHC $GHC_VERSION was not found. Installing via ghcup." && \
        ghcup install ghc $GHC_VERSION ; \
    fi

# Set the GHC version.
RUN ghcup set ghc $GHC_VERSION

# Install cabal-iinstall
RUN ghcup install cabal

# Install global packages.
RUN cabal install --global --lib QuickCheck ansi-terminal random threepenny-gui

ENV DEBIAN_FRONTEND=dialog

ENTRYPOINT ["/bin/bash"]
