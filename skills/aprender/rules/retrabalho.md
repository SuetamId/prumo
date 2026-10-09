# Retrabalho — a pergunta que ninguém faz sozinho

Lido por `prova` antes de dizer "pronto" e por `revisar` ao fechar. Custo zero.

Focado em entregar, o agente não para para registrar — e a lição só vira memória quando
alguém pede. Este checkpoint faz a pergunta toda vez. **Retrabalho é o sinal:** onde a
sessão errou e voltou, a próxima vai errar igual.

## 1. Liste o retrabalho da sessão

Releia a sessão procurando só isto — fato, não impressão:

| Sinal | Como reconhecer |
|---|---|
| **Correção da pessoa** | ela disse que o que você fez ou supôs estava errado |
| **Comando que falhou e passou de outro jeito** | mesmo objetivo, segunda forma — flag, variável, caminho, ordem |
| **Gate vermelho que pediu correção** | `lint`/`teste`/`build` falhou por algo que não era o defeito da tarefa |
| **Achado importante do revisor** | `revisar` bloqueou e você corrigiu; ou o mesmo achado voltou entre rodadas ou entre PRs |
| **Plano desmentido pelo código** | a execução saiu do plano porque uma premissa era falsa |
| **Investigação cara sem memória** | `memory_search` voltou vazio e custou ler muito código para descobrir |

Nenhum? Escreva `Retrabalho: nenhum` e feche — a linha prova que a pergunta foi feita.

## 2. Filtre pela admissão

Para cada item, a admissão de `../SKILL.md` decide: **contradiz o que um modelo assumiria
por padrão**, ou **é correção de rota do agente**? Nenhum dos dois → descarte em silêncio.
Erro de digitação, flakiness e defeito da própria tarefa não ensinam nada à próxima sessão.

Já existe memória sobre isso? Não é lição nova — é **confirmação**. Local: sugira subir
`confianca` e `visto_em` dela. No Hub (`memory_search`): só diga "já existe (id N)" — não há
como atualizar de fora, e propor de novo o servidor recusa.

## 3. Sugira — não grave

Uma linha por candidata, com o destino já decidido (`hub.md`):

```text
Retrabalho: 2 candidatas
1. [hub · time] ao rodar teste em projeto Angular → usar `--watch=false`; sem isso trava (comando-falhou)
2. [local] ao ler perfil.tsv em worktree → cair para o checkout principal (achado do revisor)
Registro? (todas · 1 · nenhuma)
```

🔴 **Nada é gravado nem proposto sem o "sim" da pessoa.** Com o sim, siga `../SKILL.md` —
local — ou `hub.md` — time ou organização. No Hub ela ainda entra como candidata e passa
pela curadoria.

Máximo de três candidatas por sessão: se há mais, escolha as que mais custaram. Lista longa
ensina a pessoa a responder "nenhuma".
