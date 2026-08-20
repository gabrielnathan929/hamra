# Backup de Repacks DODI — Guia Completo

Este repositório guarda as **ferramentas** de backup à prova de corrupção de
repacks (instaladores de jogos Windows). Os **jogos em si** ficam na pasta
`games` do NAS (`/data/games`), organizados por pasta — cada uma contém:

- Os arquivos do instalador (`Setup.exe`, `data*.doi`, etc.)
- `checksums.sha256` — impressão digital de cada arquivo
- Arquivos `.par2` — blocos de recuperação que **reparam corrupção sozinho**

## Ativação

No host, ative `hamra.programs.optionals.games.repacks = true`. Isso instala
os comandos `pack-repack`, `restore-repack`, `verify-repack` e `repair-zip`
(mais `par2cmdline`, `unzip`, `zip` e `rclone`).

No zsh, aliases disponíveis: `repack-backup`, `repack-restore` e `repair-zip`.

---

## 1. Empacotar (automatico)

```bash
pack-repack
```

Sem argumentos, o script **procura repacks em ~/Downloads** e pergunta qual
processar. Tambem aceita um caminho direto:

```bash
pack-repack "/caminho/do/repack"
```

Ele move a pasta para `$REPACK_DST` (`~/Installers` por padrão), gera o checksum e os `.par2` por
arquivo. Em outro PC, rode `verify-repack` na pasta. Pronto, pode subir.

### Paths padrao (nao precisa decorar caminho)

| Variavel | Padrao | O que controla |
|---|---|---|
| `REPACK_SRC` | `~/Downloads` | onde procurar repacks |
| `REPACK_DST` | `~/Installers` | onde guardar o backup |
| `REPACK_REDUNDANCIA` | `2` | % de recuperacao (arquivos grandes) |
| `REPACK_REDUNDANCIA_PEQUENOS` | `5` | % de recuperacao (arquivos < 1GB) |

Para usar outras pastas, defina a variavel na frente:

```bash
REPACK_DST=~/MeusRepacks pack-repack
REPACK_SRC=~/Downloads REPACK_DST=~/Installers pack-repack
```

---

## 2. Subir para a nuvem: **PASTA, nao ZIP**

**Suba a pasta inteira, arquivo por arquivo. Nao zip.**

Por que pasta vence o zip aqui:

| | Pasta (recomendado) | Zip único |
|---|---|---|
| Download que cai no meio | Retoma de onde parou, arquivo por arquivo | Re-baixa 33GB do zero |
| Arquivo corrompido no download | Só re-baixa **aquele** arquivo (ou o par2 repara) | Re-baixa tudo |
| Verificação | `sha256sum -c` arquivo a arquivo | CRC do zip inteiro |
| Google Drive/OneDrive | Upload/donwload retomável, sem limite de 4GB | Zip de 33GB vira arquivo único frágil |

O Drive e o OneDrive **nao corrompem arquivos** (fazem checksum interno).
O risco real e o download interrompido ou bitrot no seu HD — e os `.par2`
cobrem exatamente isso.

> **Quando zip faz sentido?** Só se for mandar por Telegram/WhatsApp
> (limite de 2GB por arquivo) — e ai nem cabe, porque o `data1.doi` tem 33GB.
> Para Drive/OneDrive: pasta, sem zip.

### OneDrive baixa pasta como ZIP (site web)

O site do OneDrive/Drive **zipa a pasta automaticamente** no download.
Tem dois caminhos:

**Opcao A — rclone (recomendado, sem zip e retomavel):** configurar uma vez:

```bash
rclone config        # escolha "onedrive" ou "drive", siga o fluxo
```

Depois e so sincronizar (subir e baixar sao espelhos, pasta real):

```bash
# subir
rclone copy ~/Installers onedrive:Repacks --progress --checksum

# baixar (em outro PC, sem este toggle: sudo pacman -S rclone)
rclone copy onedrive:Repacks ~/Repacks --progress --checksum
```

**Opcao B — baixar pelo site (zip):** baixa o `.zip`, extrai:

```bash
unzip repack.zip -d ~/Downloads/
```

O `unzip` valida o CRC de cada arquivo sozinho. Depois:

```bash
restore-repack ~/Downloads/"pasta-extraida"
```

Se algo chegou corrompido no zip, o `restore-repack` detecta e repara com
os `.par2`. A protecao continua valendo nos dois caminhos.

---

## 3. Restaurar em outro PC (automatico)

Baixe a pasta da nuvem e:

```bash
restore-repack "pasta-baixada"
```

Sem argumentos ele procura em `$REPACK_DST` (`~/Installers`) e `$REPACK_SRC` (`~/Downloads`). O script:
1. Verifica o checksum de cada arquivo
2. Se algo corrompeu, **repara sozinho** com os `.par2`
3. Avisa quando esta pronto

Depois é só instalar:

```bash
cd "pasta-do-repack"
wine Setup.exe
```

---

## 4. Requisitos

Com o toggle `repacks` ativo no NixOS, tudo vem junto. Em outros sistemas:

| Ferramenta | Onde |
|---|---|
| `par2` | NixOS: toggle `repacks` (par2cmdline). Arch: `sudo pacman -S par2cmdline`. Debian/Ubuntu: `sudo apt install par2` |
| `sha256sum` | Ja existe em todo Linux (coreutils) |
| `rclone` | NixOS: toggle `rclone` (`hamra.programs.optionals.backup.rclone`). Outros: `sudo pacman -S rclone` (Arch) |
| `wine` | Para instalar os repacks de Windows no Linux |

---

## 5. Boas praticas

- **Nao apague os `.par2`** — sao o seguro contra bitrot e download corrompido
- Guarde uma copia do `checksums.sha256` fora da pasta (ex.: na nuvem, solto)
- Se for HD antigo/pendrive, suba a redundancia: `REPACK_REDUNDANCIA=5 pack-repack pasta`
- Verifique o repack **antes** de apagar o original do Downloads

## 6. Como funciona a protecao (testado)

1. Corrompi um arquivo de proposito (`data2.doi`)
2. O `par2 verify` detectou: `Target damaged. Found 1999 of 2000 data blocks`
3. O `par2 repair` restaurou o arquivo
4. `sha256sum -c` confirmou: `SUCESSO` em todos

Ou seja: **corrupcao detectada e corrigida automaticamente** — e isso que
garante que o que voce baixar da nuvem daqui a anos vai instalar.