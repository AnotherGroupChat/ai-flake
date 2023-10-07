# WARNING: This file was automatically generated. You should avoid editing it.
# If you run pynixify again, the file will be either overwritten or
# deleted, and you will lose the changes you made to it.

{ buildPythonPackage,
fetchPypi,
lib,
poetry-core,
transformers,
torch,
sentencepiece}:

buildPythonPackage rec {
  pname = "torch-grammar";
  version = "0.3.3";
  format = "pyproject";

  src = fetchPypi {
    inherit version;
    pname = "torch_grammar";
    sha256 = "0c3mpdwm8id4636n1avh68xji8mgzid61sfvs3v7m4ybx3yaynbd";
  };

  nativeBuildInputs = [
    poetry-core
  ];

  propagatedBuildInputs = [
    transformers
    torch
    sentencepiece
  ];

  # TODO FIXME
  doCheck = false;

  meta = with lib; { };
}
