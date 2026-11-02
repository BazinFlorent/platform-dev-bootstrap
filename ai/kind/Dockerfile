ARG KIND_NODE_IMAGE
FROM ${KIND_NODE_IMAGE}

ARG NVIDIA_CONTAINER_TOOLKIT_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg2 \
    && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
       | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
       | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
       > /etc/apt/sources.list.d/nvidia-container-toolkit.list \
    && apt-get update \
    && apt-get install -y \
       nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
       nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
       libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
       libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
    && rm -rf /var/lib/apt/lists/*