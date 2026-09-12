#!/usr/bin/env bash
# omarchy:summary=Testa e tenta recuperar ZIPs corrompidos (OneDrive web)
# omarchy:group=custom
# omarchy:hidden=true
# repair-zip.sh - Testa arquivos ZIP (OneDrive/Drive web) e tenta recuperar.
#
# Contexto: o OneDrive/Drive web baixa PASTAS como ZIP. Zips grandes chegam
# truncados (download cortado) ou corrompidos - o unzip reclama de CRC.
#
# Uso:
#   repair-zip.sh arquivo.zip
#   repair-zip.sh *.zip
#
# Limitacoes honestas:
#   - ZIP truncado no final (download cortado): o zip -FF entra em loop e
#     NAO recupera. A unica solucao confiavel e re-baixar com rclone
#     (que baixa a pasta real, sem zip, retomavel e valida por hash).
#   - Corrupcao no meio: o zip -FF pode recuperar, mas e lento e pode
#     precisar de intervencao manual.

set -euo pipefail

FAILED=0

for ZIP in "$@"; do
  [ -f "$ZIP" ] || { echo "ERRO: '$ZIP' nao existe"; FAILED=1; continue; }
  echo "== Testando: $ZIP =="

  if unzip -tq "$ZIP" >/dev/null 2>&1; then
    echo "  OK: zip integro, sem corrupcao."
    continue
  fi

  echo "  CORROMPIDO - tentando reconstrucao (max 60s)..."
  OUT="${ZIP%.zip}-reparado.zip"
  rm -f "$OUT"
  timeout 60 zip -FF "$ZIP" --out "$OUT" </dev/null >/dev/null 2>&1 || true

  if [ -f "$OUT" ] && unzip -tq "$OUT" >/dev/null 2>&1; then
    echo "  REPARADO: $OUT"
    echo "  ATENCAO: confira os arquivos por dentro - o reparo pode ter perdido dados."
  else
    rm -f "$OUT"
    FAILED=1
    echo "  FALHA: zip truncado ou muito danificado - zip -FF nao da conta."
    echo "  SOLUCAO DEFINITIVA: re-baixe com rclone (sem zip, retomavel):"
    echo "    rclone copy onedrive:\"pasta-original\" ./ --progress --checksum"
  fi
done

exit $FAILED