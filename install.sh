#!/bin/bash

# Default values
CONTAINER_NAME="local-ai"
PORT_MAPPING="8080:8080"

# Help message
show_help() {
    echo "install.sh - Launches LocalAI with GPU or CPU depending on your system"
    echo
    echo "LocalAI is an open-source alternative to OpenAI APIs that runs models locally using Docker."
    echo "This script detects your GPU (NVIDIA, AMD, Intel) and chooses the appropriate LocalAI image."
    echo
    echo "Usage:"
    echo "  ./install.sh [OPTIONS]"
    echo
    echo "Options:"
    echo "  --name <container_name>     Set the Docker container name (default: local-ai)"
    echo "  -p <host_port:container_port>  Set the port mapping (default: 8080:8080)"
    echo "  --help                      Show this help message and exit"
    echo
    echo "Examples:"
    echo "  ./install.sh"
    echo "  ./install.sh --name my-ai -p 9090:8080"
    echo
    echo "If a GPU is detected, you'll be asked whether to use it. If not, it defaults to CPU."
}

# Parse optional arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name) CONTAINER_NAME="$2"; shift ;;
        -p) PORT_MAPPING="$2"; shift ;;
        --help) show_help; exit 0 ;;
        *) echo "Unknown parameter: $1"; echo "Use --help to see available options."; exit 1 ;;
    esac
    shift
done

# Ask the user to choose between GPU or CPU
ask_gpu_or_cpu() {
    read -p "GPU(s) detected. Do you want to use GPU? (y/n): " choice
    case "$choice" in
        y|Y ) return 0 ;;
        n|N ) return 1 ;;
        * ) echo "Invalid input. Please type 'y' for GPU or 'n' for CPU."; ask_gpu_or_cpu ;;
    esac
}

echo "Detecting GPU..."

# Check for NVIDIA GPU
if command -v nvidia-smi &> /dev/null; then
    CUDA_VERSION=$(nvidia-smi | grep -oP "CUDA Version: \K[0-9]+\.[0-9]+" | cut -d. -f1)
    echo "NVIDIA GPU detected with CUDA $CUDA_VERSION"

    if ask_gpu_or_cpu; then
        if [[ "$CUDA_VERSION" == "12" ]]; then
            docker run -ti --name "$CONTAINER_NAME" -p "$PORT_MAPPING" --gpus all localai/localai:latest-gpu-nvidia-cuda-12
        elif [[ "$CUDA_VERSION" == "11" ]]; then
            docker run -ti --name "$CONTAINER_NAME" -p "$PORT_MAPPING" --gpus all localai/localai:latest-gpu-nvidia-cuda-11
        else
            echo "Unsupported CUDA version: $CUDA_VERSION"
            exit 1
        fi
        exit 0
    fi

# Check for AMD GPU
elif lspci | grep -i 'AMD/ATI' | grep -i 'vga' &> /dev/null; then
    echo "AMD GPU detected"

    if ask_gpu_or_cpu; then
        docker run -ti --name "$CONTAINER_NAME" -p "$PORT_MAPPING" \
            --device=/dev/kfd --device=/dev/dri --group-add=video \
            localai/localai:latest-gpu-hipblas
        exit 0
    fi

# Check for Intel GPU
elif lspci | grep -i 'Intel' | grep -i 'vga' &> /dev/null; then
    echo "Intel GPU detected"

    if ask_gpu_or_cpu; then
        if command -v clinfo &> /dev/null; then
            if clinfo | grep -q "FP16"; then
                echo "Intel GPU with FP16 support detected"
                docker run -ti --name "$CONTAINER_NAME" -p "$PORT_MAPPING" localai/localai:latest-gpu-intel-f16
            elif clinfo | grep -q "FP32"; then
                echo "Intel GPU with FP32 support detected"
                docker run -ti --name "$CONTAINER_NAME" -p "$PORT_MAPPING" localai/localai:latest-gpu-intel-f32
            else
                echo "Intel GPU detected but no FP16 or FP32 support found"
                exit 1
            fi
        else
            echo "'clinfo' is not installed. Please install it to detect Intel FP16/FP32 support."
            exit 1
        fi
        exit 0
    fi

else
    echo "No GPU detected."
fi

echo "Running in CPU mode..."
docker run -ti --name "$CONTAINER_NAME" -p "$PORT_MAPPING" localai/localai:latest
