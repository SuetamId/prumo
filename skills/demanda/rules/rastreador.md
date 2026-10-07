# Registrar no rastreador

Lido por `demanda` no passo 6. Custo zero. Escrito para o Jira; vale o mesmo para outro
rastreador com outras chamadas.

## Antes de escrever

1. **Destino confirmado** — projeto, tipo, épico pai, labels. Confirmação do texto sem destino
   não basta.
2. **Formato do projeto** — o formato veio das issues recentes (passo 4). Os **labels**
   também: repita o padrão que já existe (ex.: produto + domínio), sem inventar categoria nova.
3. **Uma escrita só.** Se a chamada falhar ou der timeout, **busque antes de tentar de novo** —
   a issue pode ter sido criada. Duas issues iguais custam mais que um erro visível.

## O que criar

| Pedido | Cria |
|---|---|
| uma funcionalidade | uma **Story**, filha do épico certo |
| um conjunto grande (várias histórias) | um **Epic** com o objetivo + as Stories que já estiverem claras |
| complementar algo existente | **comentário** ou atualização da issue existente — com a pessoa de acordo, e preservando o que outros escreveram |

🔴 **Não crie Tasks técnicas nem subtarefas.** A divisão por camada (`[BACKEND]`,
`[FRONTEND]`…) nasce do `plano`, por quem lê o código de cada repositório.

## Provar o registro

1. **Releia a issue pela chave** e confira: título, tipo, pai, labels e que o texto chegou
   inteiro (tabelas e listas viram outra coisa em alguns formatos).
2. Devolva o **link** e o estado real. "Criei" só depois de reler.
3. Pendências abertas: deixe-as visíveis na issue (seção própria) e diga quem decide cada uma.

## Nunca

- Criar sem o "sim" explícito para o conteúdo e o destino.
- Transicionar status, atribuir pessoa ou mudar prioridade sem pedido.
- Colar segredo, dado pessoal de cliente ou print com dado sensível na issue.
