{ lib
, buildPythonPackage
, fetchFromGitHub
, safetensors
, accelerate
, rouge
, peft
, transformers
, datasets
, torch
, cudaPackages
, symlinkJoin
, which
, ninja
, cudaArchList ? [ "8.6+PTX" ]
, gcc11Stdenv
, pybind11
}:
let
  cuda-native-redist = symlinkJoin {
    name = "cuda-redist";
    paths = with cudaPackages; [
      cuda_cudart # cuda_runtime.h
      cuda_nvcc
    ];
  };
in

buildPythonPackage rec {
  pname = "autogptq";
  version = "0.3.2";
  format = "setuptools";

  BUILD_CUDA_EXT = "1";

  CUDA_HOME = cuda-native-redist;
  TORCH_CUDA_ARCH_LIST = "${lib.concatStringsSep ";" cudaArchList}";

  buildInputs = [
    cudaPackages.cudatoolkit
  ];

  preBuild = ''
    export PATH=${gcc11Stdenv.cc}/bin:$PATH
  '';

  nativeBuildInputs = [
    which
    ninja
  ];

  src = fetchFromGitHub {
    owner = "PanQiWei";
    repo = "AutoGPTQ";
    rev = "v${version}";
    hash = "sha256-mWGD8+QLBNFV9eDIfCLDrW6qZuZYIXNe229jmMyayMo=";
  };

  pythonImportsCheck = [ "auto_gptq" ];

  propagatedBuildInputs = [
    safetensors
    accelerate
    rouge
    peft
    transformers
    datasets
    torch
    pybind11
  ];

  meta = with lib; {
    description = "An easy-to-use LLMs quantization package with user-friendly apis, based on GPTQ algorithm";
    homepage = "https://github.com/PanQiWei/AutoGPTQ";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
