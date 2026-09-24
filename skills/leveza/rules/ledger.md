# Ledger de dívida — colher o que foi deixado para depois

Lido sob demanda. Custo residente zero.

## Por que existe

A escada autoriza atalho com teto conhecido. Sem registro, o atalho é indistinguível de
descuido seis meses depois, e "depois" vira "nunca" em 100% dos casos não medidos.

## A marca

```
<comentário da linguagem> leveza: <o teto real>; <o caminho de saída>
```

Regras da marca, e as três são mecânicas:

1. **Nomeia o teto**, não a intenção. `lock global` é teto; `pode melhorar` não é.
2. **Nomeia a saída.** Sem o caminho, ninguém sabe o que fazer quando o teto chegar.
3. **Só para atalho deliberado.** TODO genérico não entra — isso é outra coisa e tem
   outro dono.

## Colher

```bash
grep -rn --include='*.*' -E '(#|//|/\*|--) ?leveza:' . \
  | grep -v node_modules | grep -v '\.git/'
```

Saída para `docs/ai-harness/divida.md`, uma linha por marca: arquivo:linha · teto ·
saída · data em que foi colhida. O arquivo é **gerado** — não edite à mão, regenere.

## Quando promover a dívida

Uma marca vira task quando **o teto chegou**, não quando alguém se incomodou com ela.
Teto que nunca chegou é atalho que estava certo — e refatorar isso é o oposto de leveza.
