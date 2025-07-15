# What is LocalAI?

LocalAI is a free, open-source alternative to OpenAI (Anthropic, etc.), functioning as a drop-in replacement REST API for local inferencing. It allows you to run LLMs, generate images, and produce audio, all locally or on-premises with consumer-grade hardware, supporting multiple model families and architectures.

# Using the Bash Installer 
```
curl https://localai.io/install.sh | sh
```
# Run with docker
#### CPU only image
```
docker run -ti --name local-ai -p 8080:8080 localai/localai:latest
```

#### NVIDIA GPU Images
##### to know which version is your CUDA, you can run `nvidia-smi | grep CUDA`
```
# CUDA 12.0
docker run -ti --name local-ai -p 8080:8080 --gpus all localai/localai:latest-gpu-nvidia-cuda-12

# CUDA 11.7
docker run -ti --name local-ai -p 8080:8080 --gpus all localai/localai:latest-gpu-nvidia-cuda-11

# NVIDIA Jetson (L4T) ARM64
# First, you need to have installed the nvidia container toolkit: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-with-ap
docker run -ti --name local-ai -p 8080:8080 --runtime nvidia --gpus all localai/localai:latest-nvidia-l4t-arm64
```

#### Intel GPU Images (oneAPI)
```
# Intel GPU with FP16 support
docker run -ti --name local-ai -p 8080:8080 localai/localai:latest-gpu-intel-f16

# Intel GPU with FP32 support
docker run -ti --name local-ai -p 8080:8080 localai/localai:latest-gpu-intel-f32
```

#### AMD GPU Images (ROCm)
```
docker run -ti --name local-ai -p 8080:8080 --device=/dev/kfd --device=/dev/dri --group-add=video localai/localai:latest-gpu-hipblas
```