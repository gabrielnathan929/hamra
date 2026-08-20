#!/usr/bin/env bash
# omarchy:summary=Verifica e repara repack baixado (sha256 + par2)
# omarchy:group=custom
# omarchy:hidden=true
# restore-repack.sh - Restaura/verifica um repack baixado da nuvem.
#
# Uso:
#   restore-repack.sh                    # procura repacks em ~/Instaladores e ~/Downloads
#   restore-repack.sh "pasta-do-repack"  # verifica a pasta indicada
#
# O que ele faz:
#   1. Verifica o checksum de cada arquivo
#   2. Se algo corrompeu (ex.: download interrompido), repara sozinho com .par2
#   3. Avisa quando esta tudo pronto para instalar

set -euo pipefail

par2_bin() {
  if command -v par2 >/dev/null 2>&1; then echo "par2"; return; fi
  for p in "/.local/bin/par2" /usr/bin/par2 /usr/local/bin/par2; do
    [ -x "" ] && { echo ""; return; }
  done
  echo "ERRO: par2 nao encontrado. Compile em ~/.local ou instale par2cmdline." >&2
  exit 1
}
PAR2="$(par2_bin)"

if [ $# -lt 1 ]; then
  DIRS=("$HOME/Instaladores"/*/ "$HOME/Downloads"/*/)
  for D in "${DIRS[@]}"; do
    if [ -f "$D/checksums.sha256" ]; then
      DIR="$D"
      break
    fi
  done
  [ -n "${DIR:-}" ] || { echo "Nenhum repack com checksums encontrado. Passe o caminho: $0 /pasta"; exit 1; }
else
  DIR="$1"
fi

[ -d "$DIR" ] || { echo "ERRO: '$DIR' nao e uma pasta"; exit 1; }
cd "$DIR"
[ -f checksums.sha256 ] || { echo "ERRO: checksums.sha256 nao existe em $DIR"; exit 1; }

echo "== Verificando integridade =="
if sha256sum -c checksums.sha256; then
  echo
  echo "TUDO OK - pode instalar: wine Setup.exe"
  exit 0
fi

echo
echo "!! Corrupcao detectada - tentando reparo com par2 =="
if ! ls ./*.par2 >/dev/null 2>&1; then
  echo "ERRO: sem .par2 na pasta. Recopie o backup ou re-baixe os arquivos danificados."
  exit 1
fi

for P in ./*.par2; do
  echo "  - reparando com $P"
  "$PAR2" repair -q "$P" || true
done

echo
echo "== Re-verificando =="
if sha256sum -c checksums.sha256; then
  echo
  echo "REPARO OK - pode instalar: wine Setup.exe"
else
  echo
  echo "FALHA: reparo insuficiente. Re-baixe os arquivos danificados da nuvem."
  exit 1
fi