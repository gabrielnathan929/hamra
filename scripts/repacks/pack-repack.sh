#!/usr/bin/env bash
# omarchy:summary=Empacota repack para backup a prova de corrupcao (par2 + checksum)
# omarchy:group=custom
# omarchy:hidden=true
# pack-repack.sh - Empacota um repack para backup à prova de corrupção.
#
# Uso:
#   pack-repack.sh                       # procura repacks em ~/Downloads automaticamente
#   pack-repack.sh "pasta-do-repack"     # processa a pasta indicada
#
# Paths padrão (mude as variáveis abaixo se quiser):
#   ORIGEM   = ~/Downloads    (onde repacks baixados costumam estar)
#   DESTINO  = ~/Instaladores (onde o backup protegido fica)
#
# O que ele faz:
#   1. Detecta os arquivos do repack (ignora .par2 e checksums antigos)
#   2. Move a pasta para ~/Instaladores
#   3. Gera checksums.sha256 (validação)
#   4. Gera .par2 POR ARQUIVO (2% de recuperação; 5% para arquivos pequenos)
#
# IMPORTANTE: roda par2 por arquivo de propósito - o par2cmdline 0.8.1
# ignora o primeiro argumento em chamadas multi-arquivo (bug conhecido).

set -euo pipefail

ORIGEM="${REPACK_SRC:-$HOME/Downloads}"
DESTINO="${REPACK_DST:-$HOME/Instaladores}"
REDUNDANCIA="${REPACK_REDUNDANCIA:-2}"
REDUNDANCIA_PEQUENOS="${REPACK_REDUNDANCIA_PEQUENOS:-5}"

# Detecta o par2 em vários lugares (este PC e outros PCs comuns)
par2_bin() {
  if command -v par2 >/dev/null 2>&1; then echo "par2"; return; fi
  for p in "/.local/bin/par2" /usr/bin/par2 /usr/local/bin/par2; do
    [ -x "" ] && { echo ""; return; }
  done
  echo "ERRO: par2 nao encontrado. Compile em ~/.local ou instale par2cmdline." >&2
  exit 1
}
PAR2="$(par2_bin)"

# Se nenhum argumento: procura repacks na ORIGEM
if [ $# -lt 1 ]; then
  mapfile -t REPACKS < <(find "$ORIGEM" -maxdepth 1 -type d -name "*[Dd][Oo][Dd][Ii]*" 2>/dev/null)
  if [ ${#REPACKS[@]} -eq 0 ]; then
    echo "Nenhum repack encontrado em $ORIGEM"
    echo "Passe o caminho: $0 /caminho/do/repack"
    exit 1
  fi
  echo "Repacks encontrados em $ORIGEM:"
  for i in "${!REPACKS[@]}"; do
    SZ=$(du -sh "${REPACKS[$i]}" 2>/dev/null | cut -f1)
    echo "  $((i+1)). $(basename "${REPACKS[$i]}") ($SZ)"
  done
  read -rp "Escolha o numero (ou 0 para cancelar): " SEL
  [ "${SEL:-0}" -gt 0 ] 2>/dev/null || exit 1
  DIR="${REPACKS[$((SEL-1))]}"
else
  DIR="$1"
fi

[ -d "$DIR" ] || { echo "ERRO: '$DIR' nao e uma pasta"; exit 1; }
DIR="$(realpath "$DIR")"

# Move para o destino se ainda nao estiver la
if [[ "$DIR" != "$DESTINO"/* ]]; then
  mkdir -p "$DESTINO"
  echo "== Movendo para $DESTINO =="
  mv "$DIR" "$DESTINO"/ 2>/dev/null || {
    echo "ERRO: nao consegui mover (mesmo filesystem?). Copie manualmente e rode de novo."
    exit 1
  }
  DIR="$DESTINO/$(basename "$DIR")"
fi

cd "$DIR"

# Arquivos do repack: tudo menos par2/checksums antigos
mapfile -t FILES < <(find . -maxdepth 1 -type f ! -name "*.par2" ! -name "checksums.sha256" -printf "%f\n" | sort)

[ ${#FILES[@]} -gt 0 ] || { echo "ERRO: nenhum arquivo na pasta"; exit 1; }

echo "== Gerando checksums.sha256 =="
sha256sum "${FILES[@]}" > checksums.sha256

echo "== Gerando .par2 (por arquivo) =="
for F in "${FILES[@]}"; do
  SIZE=$(stat -c %s "$F")
  RED=$REDUNDANCIA
  [ "$SIZE" -lt 1000000000 ] && RED=$REDUNDANCIA_PEQUENOS
  echo "  - $F (${RED}%)"
  "$PAR2" create -r"$RED" "$F" >/dev/null
done

echo
echo "Backup pronto: $DIR"
echo "Total protegido: $(du -sh "$DIR" | cut -f1)"
echo
echo "Agora suba a PASTA para o Drive/OneDrive (nao zip, veja README.md)."
echo "No outro PC, rode: verify-repack \"$DIR\""