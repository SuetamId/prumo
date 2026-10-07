# Hub de memória — o que vale para o time

Lido por `aprender` e `triagem` quando as ferramentas `memory_search` / `memory_propose`
estão disponíveis (servidor MCP do Hub configurado pelo `prumo-workspace --hub`). Custo zero.

## Três destinos, um por lição

| A lição vale para | Destino |
|---|---|
| só este repositório | `docs/ai-harness/memoria/` — o instinto local de sempre |
| o produto inteiro — todos os repositórios do time | `memory_propose` |
| todos os produtos da empresa | `memory_propose` com `company_wide: true` |

Na dúvida entre dois, escolha o **menor**. Memória larga demais aparece onde não ajuda e
ensina o time a ignorar a busca.

## Propor

1. **Busque antes** (`memory_search` com o mesmo assunto). Já existe? Leia com `memory_read`;
   não proponha de novo — o servidor recusa título repetido (`DUPLICATE`).
2. Os campos do instinto viram os da proposta:

   | Instinto | `memory_propose` |
   |---|---|
   | `gatilho` | `trigger_when` |
   | `acao` | `action` |
   | `dominio` | `domain` |
   | `confianca` | `confidence` |
   | evidência datada | `body` |
   | a lição em uma linha | `title` |

3. `remote` = `git remote get-url origin`. É ele que diz de que time é o repositório.
4. A proposta entra como **candidata**: só aparece na busca depois que um admin do time
   admite. Diga isso à pessoa — "proposto ao time", nunca "registrado".

🔴 **Nunca segredo.** O servidor recusa (`SECRET_DETECTED`) e nada é gravado — mas o segredo
já passou pela conversa. Valor de máquina vira nome de variável; credencial, nunca.

## Buscar (triagem)

No começo da tarefa: `memory_search` com o `remote` e o assunto do pedido em poucas
palavras. O que volta foi admitido por gente — trate como regra do time.

- `expired: true` → passou do prazo; confira antes de aplicar.
- Lista vazia → a busca rodou e não achou. Siga.

## Quando o Hub falha

| Erro | O que fazer |
|---|---|
| `UNKNOWN_REPOSITORY` | o repositório não está cadastrado em nenhum time — diga em uma linha e siga sem o Hub |
| `NOT_A_MEMBER` | a pessoa não é do time dono deste repositório — idem |
| `UNAUTHORIZED` / sem resposta | chave inválida ou servidor fora — diga, siga sem, e grave a lição local se for o caso |

Nunca invente o que a memória "provavelmente diria". Sem Hub, a tarefa segue com o que
está no repositório.
