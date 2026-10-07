# Trabalho que atravessa repositórios

Lido por `plano` quando a mudança toca mais de um repositório — front e API separados,
worker, site. Custo zero.

Os repositórios irmãos vêm do `perfil.tsv` (`repos_irmaos`, declarado). Sem a linha,
pergunte uma vez e grave como `declarado:` — ver `../../triagem/rules/adocao.md`.

## O plano é um só

Um `plan.md`, no repositório onde a tarefa começou. Cada wave diz **em qual repositório**
roda, com o caminho e o comando de prova daquele repositório. Dois planos que dependem
um do outro divergem na primeira decisão que só um deles registrou.

## Contrato antes de código

Se um repositório consome o que outro produz (endpoint, evento, schema, tipo), o
contrato vai no plano **antes** da primeira wave: forma, campos, erros, quem muda primeiro.

🔴 **Durante a transição, os dois lados convivem com a versão anterior.** O front novo
fala com a API velha até a API subir; a API nova atende o front velho até o front subir.
Campo novo entra opcional; campo removido sai só depois que ninguém o lê.

Para saber quem lê, procure em **todos** os irmãos, não só no repositório que você abriu:

```bash
for r in <repos_irmaos>; do git -C "$r" grep -n '<campo-ou-rota>'; done
```

## Ordem de merge

1. Migração de dado — e só se for compatível com o código que já está em produção
2. Quem **produz** (API, worker)
3. Quem **consome** (front, site)
4. Limpeza do que ficou obsoleto — em PR separado, depois

Ordem invertida é janela em que produção quebra.

## Pronto

🔴 **A entrega está pronta quando o repositório mais atrasado estiver pronto.** Três de
quatro PRs mergeados é zero entregue para o usuário. O PR de cada repositório cita os
outros, e a prova final roda com todos juntos.
