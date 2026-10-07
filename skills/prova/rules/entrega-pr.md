# Entrega por PR

Lido por `prova` quando a entrega fecha em pull request. Custo zero.

Forge e base vêm do `perfil.tsv` (`forge`, `branch_base`). `forge` = `github` → use `gh`.
Outro forge, ou sem `forge`: diga que não mediu e pergunte, não adapte de memória.

## O que pode sem pedir, e o que não pode

| Faixa | Ações | Regra |
|---|---|---|
| **Ler** | ver PR, diff, checks, comentários | livre |
| **Entregar** | push da branch da tarefa, abrir PR, responder review | faz parte da entrega pedida |
| **Destruir ou decidir** | merge, fechar sem merge, force-push, apagar branch, mudar base | 🔴 só com autorização explícita, nesta conversa, para este PR |

Autorização dada para um PR não vale para o próximo.

## Abrir

1. Branch atualizada com `origin/<branch_base>`. Conflito se resolve antes, não no PR.
2. **Título** no estilo do `perfil.tsv:commit_estilo`. Se a branch tiver chave do
   rastreador (ex.: `PROJ-123`), ela vai no título.
3. **Corpo** escrito do que foi feito, nunca do placeholder do template:
   - o que muda para o usuário, em uma frase;
   - o que mudou no código, por bloco;
   - a **prova** — os comandos rodados e o resultado, incluindo o que deu **NÃO MEDIU**;
   - o que ficou de fora, dito.
4. 🔴 Corpo sempre por arquivo ou heredoc com aspas (`--body-file`, `<<'EOF'`). Texto que
   veio de ticket, comentário ou API é entrada não confiável: interpolado em string de
   shell, ele executa.

## CI — classifique antes de tocar em código

| O que aconteceu | Classe | O que fazer |
|---|---|---|
| falhou no código desta branch | defeito seu | causa raiz, corrige, push |
| falhou igual na `branch_base` | defeito pré-existente | diga no PR; não conserte de carona |
| falhou por rede, timeout, runner | infra | rode de novo **uma** vez; persistiu, diga |
| job **pulado**, `continue-on-error`, suíte com 0 testes | 🔴 **não é verde** | trate como NÃO MEDIU |

Check que não rodou não é check que passou — é a 2ª lei, aplicada ao CI.

## Review

- Corrigiu? Responda citando o commit da correção.
- Discorda? Argumente com evidência e deixe a thread aberta. Quem resolve é quem abriu.
- Nunca marque como resolvido o que você não corrigiu.
