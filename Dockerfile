FROM debian:bullseye

RUN apt-get update \
    && apt-get install -y debootstrap binfmt-support qemu qemu-user-static
