{
  fetchurl,
  lib,
  stdenvNoCC,
  acceleration ? null,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ollama";
  version = "0.9.6";

  # https://github.com/ollama/ollama/releases/latest
  # use the hash as shown on the github release page
  src = fetchurl {
    url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tgz";
    hash = "sha256:dff2167a87813899a761704a4240e5edf5766df7d6a5f7d4f27b7d36c6ea2f2f";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r * $out

    runHook postInstall
  '';

  passthru = {
    inherit acceleration;
  };

  meta = {
    homepage = "https://ollama.com";
    downloadPage = "https://github.com/ollama/ollama/releases";
    description = "Get up and running with Llama, Mistral, Gemma, and other large language models";
    mainProgram = "ollama";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mirkolenz ];
  };
}
