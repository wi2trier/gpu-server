{
  lib,
  dockerTools,
  mkShell,
  python3Packages,
}:
dockerTools.streamNixShellImage {
  drv = mkShell {
    name = "nlp-shell";
    venvDir = "./.venv";
    buildInputs = with python3Packages; [
      python
      venvShellHook
    ];
    postVenvCreation = ''
      pip install \
        "jupyterlab>=4.0,<5" \
        "numpy>=1.24,<2" \
        "scipy>=1.10,<2" \
        "spacy>=3.7,<4" \
        "nltk>=3.8,<4" \
        "torch>=2.1.1,<3" \
        "openai>=1.3,<2" \
        "transformers>=4.34,<5" \
        "sentence-transformers>=2.2,<3"
    '';
  };
  tag = "latest";
}
