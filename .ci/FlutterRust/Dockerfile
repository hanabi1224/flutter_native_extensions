FROM cirrusci/flutter:stable

RUN sudo apt-get update -y

RUN sudo apt-get install -y --no-install-recommends gnupg

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

RUN source $HOME/.cargo/env

RUN cargo -V
