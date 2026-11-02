kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = "/etc/containerd/certs.d"

nodes:
  - role: control-plane
    image: __KIND_NODE_IMAGE__
    extraMounts:
      - hostPath: __KIND_STORAGE__/control-plane
        containerPath: /var/local-path-provisioner
    extraPortMappings:
      - containerPort: 80
        hostPort: __KIND_HTTP_PORT__
        listenAddress: "127.0.0.1"
        protocol: TCP
      - containerPort: 443
        hostPort: __KIND_HTTPS_PORT__
        listenAddress: "127.0.0.1"
        protocol: TCP

  - role: worker
    image: __KIND_NODE_IMAGE__
    extraMounts:
      - hostPath: __KIND_STORAGE__/worker-1
        containerPath: /var/local-path-provisioner

  - role: worker
    image: __AI_KIND_NODE_IMAGE__
    labels:
      nvidia.com/gpu.present: "true"
    extraMounts:
      # Déclenche l'injection NVIDIA du runtime Docker hôte dans le node Kind.
      - hostPath: /dev/null
        containerPath: /var/run/nvidia-container-devices/all

      # Rend la spec CDI NVIDIA de l'hôte visible dans le worker.
      - hostPath: /etc/cdi
        containerPath: /etc/cdi
        readOnly: true

      - hostPath: __KIND_STORAGE__/gpu-worker
        containerPath: /var/local-path-provisioner
