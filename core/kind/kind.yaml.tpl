kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = "/etc/containerd/certs.d"

nodes:
  - role: control-plane
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
    extraMounts:
      - hostPath: __KIND_STORAGE__/worker-1
        containerPath: /var/local-path-provisioner

  - role: worker
    extraMounts:
      - hostPath: __KIND_STORAGE__/worker-2
        containerPath: /var/local-path-provisioner