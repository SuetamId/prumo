# Qualidade de UI — o piso que não se negocia

Lido pelo plano de UI. Custo residente zero. Vale nos quatro degraus da escada.

## Acessibilidade é piso, não feature

- HTML semântico primeiro; ARIA só para preencher lacuna que o HTML não cobre.
- **`:focus-visible`**, nunca `:focus` — `:focus` acende no clique de mouse e o time
  desliga o outline inteiro por isso, que é como produtos perdem navegação por teclado.
- Operável só com teclado, na ordem visual. Se a ordem do DOM briga com a visual, a
  ordem do DOM está errada.
- Contraste mínimo AA: 4.5:1 texto normal, 3:1 texto grande e elementos de interface.
- Alvo de toque ≥ 44px em qualquer coisa que dedo alcança.
- Ícone decorativo é `aria-hidden`; ícone que é o único rótulo precisa de nome acessível.

## Os cinco estados que ninguém descreve e todo mundo encontra

Toda superfície que carrega dado tem os cinco. Planejar só o caminho feliz é o defeito de
UI mais comum que existe:

| Estado | A pergunta que ele responde |
|---|---|
| **Vazio** | primeira vez ou filtro sem resultado? São textos diferentes e ações diferentes |
| **Carregando** | skeleton com a forma do conteúdo, não spinner centralizado |
| **Erro** | o que houve **e** o que fazer agora; "algo deu errado" não é mensagem |
| **Sem permissão** | some, ou aparece desabilitado com motivo? Sumir confunde quem espera ver |
| **Parcial** | carregou metade — mostra o que tem, não segura a tela inteira |

## Hierarquia

Uma ação primária por tela. Se há duas, uma delas é secundária e ninguém decidiu qual.
Peso visual segue importância: tamanho, cor e posição concordando entre si. Quando
discordam, o usuário obedece à cor — e é por isso que botão destrutivo colorido de
primário causa incidente.

## Ritmo

Uma escala de espaçamento, e todo espaço sai dela. Valor solto quebra o ritmo de um jeito
que ninguém aponta no review mas todo mundo sente. Densidade é decisão do produto — mas é
**uma** decisão, não uma por tela.

## Movimento

Movimento serve para explicar origem e destino. Transição que só decora custa
performance e paciência. Teto de 200ms para retorno de interação. Respeite
`prefers-reduced-motion` — não é preferência estética, é acessibilidade vestibular.

## Texto

Rótulo diz o que acontece (`Salvar alterações`), não o genérico (`OK`). Erro diz a
próxima ação. Não existe "texto provisório": o provisório vai para produção.
