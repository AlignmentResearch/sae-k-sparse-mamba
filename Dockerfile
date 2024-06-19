FROM pytorch/pytorch:2.3.1-cuda11.8-cudnn8-runtime as main-pre-pip

ARG APPLICATION_NAME
ARG USERID=1001
ARG GROUPID=1001
ARG USERNAME=dev

ENV GIT_URL="https://github.com/AlignmentResearch/${APPLICATION_NAME}"

ENV DEBIAN_FRONTEND=noninteractive
MAINTAINER Adrià Garriga-Alonso <adria@far.ai>
LABEL org.opencontainers.image.source=${GIT_URL}

RUN apt-get update -q \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    # essential for running. GCC is for Torch triton
    git git-lfs build-essential \
    # essential for testing
    libgl-dev libglib2.0-0 zip make \
    # devbox niceties
    curl vim tmux less sudo \
    # CircleCI
    ssh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Simulate virtualenv activation
ENV VIRTUAL_ENV="/opt/venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

RUN python3 -m venv "${VIRTUAL_ENV}" --system-site-packages \
    && addgroup --gid ${GROUPID} ${USERNAME} \
    && adduser --uid ${USERID} --gid ${GROUPID} --disabled-password --gecos '' ${USERNAME} \
    && usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p "/workspace" \
    && chown -R ${USERNAME}:${USERNAME} "${VIRTUAL_ENV}" "/workspace"
USER ${USERNAME}
WORKDIR "/workspace"

FROM main-pre-pip as main-pip-tools
RUN pip install "pip-tools ~=7.4.1"

FROM main-pre-pip as main
COPY --chown=${USERNAME}:${USERNAME} requirements.txt ./
# Install all dependencies, which should be explicit in `requirements.txt`
RUN pip install --no-deps -r requirements.txt \
    && rm -rf "${HOME}/.cache"

# Copy whole repo and install
COPY --chown=${USERNAME}:${USERNAME} . .
RUN pip install --require-virtualenv --no-deps -e . \
    && rm -rf "${HOME}/.cache"

CMD ["/bin/bash"]
