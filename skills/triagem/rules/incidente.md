# Incidente em produção

Lido pela `triagem` quando o pedido fala de produção: cliente afetado, erro em produção,
"caiu", "parou", "está lento". Custo zero.

As fontes vêm do `perfil.tsv` (`logs`, `metricas`, `banco_leitura`, declarados). Fonte
sem linha é fonte que você **não** consulta: pergunte, não adivinhe credencial nem host.

## Regras duras

- 🔴 **Nenhuma correção, rollback, restart ou escrita em produção sem aprovação explícita
  da pessoa, nesta conversa.** Investigar é ler. Agir é outra autorização.
- 🔴 **Banco só leitura.** Consulta que escreve, trava tabela ou varre tudo sem limite não
  é investigação.
- **Sem culpados.** O relatório fala de sistema e de sequência, não de quem.

## Fato e hipótese, sempre separados

Toda afirmação começa com um dos dois rótulos:

- **Fato:** observado, com a fonte — "Fato: 412 erros 500 em `/pedidos` entre 14:02 e
  14:31 (UTC), log do serviço X".
- **Hipótese:** o que explicaria o fato — segue o método de `rules/hipoteses.md`.

Horário em **UTC e no fuso do cliente**. Impacto **com número**: quantos clientes, quantas
requisições, quanto tempo. "Alguns usuários" não é impacto.

## Armadilhas

- **Zero também precisa de prova.** Antes de aceitar "não há erro", confirme que a
  consulta acha alguma coisa quando deveria — um período em que o erro sabidamente
  existiu. Consulta errada devolve zero com a mesma cara de consulta certa.
- **Data do merge não é data do deploy.** Quando o código entrou em produção se mede no
  deploy (tag, release, log da esteira), não no merge.
- **Correlação de horário não é causa.** Deploy às 14:00 e erro às 14:02 é hipótese.

## Relatório

1. **Resumo** — o que aconteceu, em duas frases, com impacto em número
2. **Linha do tempo** — fatos, em UTC, com fonte
3. **Causa** — a hipótese que sobreviveu, e as que caíram
4. **Ação proposta** — o que corrigir, com o risco de cada opção. Proposta, não execução
5. **Depois do deploy da correção**, dois vereditos separados:
   - **o mecanismo funcionou?** — a correção está em produção e faz o que diz;
   - **o sintoma cedeu?** — o número do resumo voltou ao normal.

   Um sem o outro não fecha o incidente.
