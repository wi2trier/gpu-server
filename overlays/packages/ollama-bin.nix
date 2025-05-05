{
  fetchzip,
  lib,
  stdenvNoCC,
  acceleration ? null,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ollama";
  version = "0.6.7";

  # to update, run etiher of the following commands:
  # nix store prefetch-file --unpack "$(nix eval --raw .#packages.x86_64-linux.ollama-bin.src.url)"
  # VERSION=x.y.z nix store prefetch-file --unpack "https://github.com/ollama/ollama/releases/download/v$VERSION/ollama-linux-amd64.tgz"
  src = fetchzip {
    url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tgz";
    hash = "sha256-/LDiS/u+x38wbHh+juQI4mvKe8fmz9qt9ma0Xbz7NFs=";
    stripRoot = false;
  };

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
