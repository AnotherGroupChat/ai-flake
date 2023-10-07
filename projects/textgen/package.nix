{ python3Packages
, lib
, src
, wsl ? false
, fetchFromGitHub
, writeShellScriptBin
, runCommand
, tmpDir ? "/tmp/nix-textgen"
, stateDir ? "$HOME/.textgen/state"
, libdrm
, cudaPackages
, gcc
}:
let

  patchedSrc = runCommand "textgen-patchedSrc" { } ''
    cp -r --no-preserve=mode ${src} ./src
    cd src
    rm -rf models loras cache
    mv ./prompts ./_prompts
    mv ./characters ./_characters
    mv ./training ./_training
    cd -
    for file in $(find src/ -type f -name "*.py"); do
      substituteInPlace $file \
        --replace "Path('cache" "Path('$out/cache" \
        --replace "Path('characters" "Path('$out/characters" \
        --replace "Path('extensions" "Path('$out/extensions" \
        --replace "Path('presets" "Path('$out/presets" \
        --replace "Path('prompts" "Path('$out/prompts" \
        --replace "Path('softprompts" "Path('$out/softprompts" \
        --replace "Path('training" "Path('$out/training" \
        --replace "Path(f'presets" "Path(f'$out/presets" \
        --replace "Path(f'prompts" "Path(f'$out/prompts" \
        --replace "Path(f'softprompts" "Path(f'$out/softprompts" \
        --replace "training/datasets" "$out/training/datasets" \
        --replace "=args.output" "='$out/models/'" \
        --replace "base_folder=None" "base_folder='$out/models/'" \
        --replace "../css" "$out/css" \
        --replace "../js" "$out/js" \
        --replace 'Path(__file__).resolve().parent / ' "" \
        --replace "Path(f'css" "Path(f'$out/css" \
        --replace "Path('css" "Path('$out/css" \
        --replace "Path('characters" "Path('$out/characters" \
        --replace "characters/" "$out/characters/" \
        --replace "folder = 'characters'" "folder = '$out/characters'" \
        --replace "Path('characters" "Path('$out/characters" \
        --replace "characters/" "$out/characters/"
    done
    mv ./src $out
    ln -s ${tmpDir}/cache/ $out/cache
    ln -s ${tmpDir}/characters/ $out/characters
    ln -s ${tmpDir}/loras/ $out/loras
    ln -s ${tmpDir}/models/ $out/models
    ln -s ${tmpDir}/prompts/ $out/prompts
    ln -s ${tmpDir}/training/ $out/training
  '';
  textgenPython = python3Packages.python.withPackages (_: with python3Packages; [
    accelerate
    (bitsandbytes.overrideAttrs (old: {
      propagatedBuildInputs = old.propagatedBuildInputs ++ (with python3Packages; [ scipy ]);
      src = pkgs.fetchFromGitHub {
        owner = "TimDettmers";
        repo = "bitsandbytes";
        rev = "0f40fa3f0a198802056e29ba183eaabc6751d565";
        hash = "sha256-AzIACOjGjwdOZMCwLLGqIdAio4oxT9risRrqEpUQ6YQ=";
      };
    }))
    colorama
    datasets
    flexgen
    gradio
    llama-cpp-python
    markdown
    numpy
    pandas
    peft
    pillow
    pyyaml
    requests
    rwkv
    safetensors
    sentencepiece
    tqdm
    transformers
    torch-grammar
    autogptq
    torch
  ]);

  # See note about consumer GPUs:
  # https://docs.amd.com/bundle/ROCm-Deep-Learning-Guide-v5.4.3/page/Troubleshooting.html
  rocmInit = ''
    if [ ! -e /tmp/nix-pytorch-rocm___/amdgpu.ids ]
    then
        mkdir -p /tmp/nix-pytorch-rocm___
        ln -s ${libdrm}/share/libdrm/amdgpu.ids /tmp/nix-pytorch-rocm___/amdgpu.ids
    fi
    export HSA_OVERRIDE_GFX_VERSION=''${HSA_OVERRIDE_GFX_VERSION-'10.3.0'}
  '';
in
(writeShellScriptBin "textgen" ''
  if [ -d "/usr/lib/wsl/lib" ]
  then
    echo "Running via WSL (Windows Subsystem for Linux), setting LD_LIBRARY_PATH"
    set -x
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib"
    set +x
  fi
  rm -rf ${tmpDir}
  mkdir -p ${tmpDir}
  mkdir -p ${stateDir}/models ${stateDir}/cache ${stateDir}/loras ${stateDir}/prompts ${stateDir}/characters
  cp -r --no-preserve=mode ${patchedSrc}/_prompts/* ${stateDir}/prompts/
  cp -r --no-preserve=mode ${patchedSrc}/_characters/* ${stateDir}/characters
  ln -s ${stateDir}/models/ ${tmpDir}/models
  ln -s ${stateDir}/loras/ ${tmpDir}/loras
  ln -s ${stateDir}/cache/ ${tmpDir}/cache
  ln -s ${stateDir}/prompts/ ${tmpDir}/prompts
  ln -s ${stateDir}/characters/ ${tmpDir}/characters
  ${lib.optionalString (python3Packages.torch.rocmSupport or false) rocmInit}
  export CC=${gcc}/bin/gcc
  export LD_LIBRARY_PATH=/run/opengl-driver/lib:${cudaPackages.cudatoolkit}/lib
  ${textgenPython}/bin/python ${patchedSrc}/server.py $@ \
    --model-dir ${stateDir}/models/ \
    --lora-dir ${stateDir}/loras/ \

'').overrideAttrs
  (_: {
    meta = {
      maintainers = [ lib.maintainers.jpetrucciani ];
      license = lib.licenses.agpl3;
      description = "";
      homepage = "https://github.com/oobabooga/text-generation-webui";
      mainProgram = "textgen";
    };
  })
