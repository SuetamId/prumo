# Seleção de instintos — ranqueada, com piso e teto

Lida por `aprender` e por `triagem`. Custo residente zero.

## O problema

Memória cresce para sempre; a janela de contexto não. Sem seleção, ou você carrega tudo
(e o orçamento estoura) ou carrega nada (e a memória não serve). Carregar "os mais
recentes" é pior que os dois: recência não tem relação com relevância.

## A fórmula

```
pontuacao = confianca
          + 0.25  se escopo=projeto e é ESTE projeto
          + 0.20  se dominio casa com a stack detectada
          + 0.10  se origem=correcao-do-usuario
```

Depois: descarta `pontuacao < 0.5` **e** `confianca < 0.4`, ordena desc, corta no teto de **12**.

🔴 **Os dois pisos existem, e o segundo foi achado testando.** Um instinto de confiança
`0.3` alcançou a pontuação `0.5` só com o bônus de stack e entrou dando ordem imperativa —
"faça X". O número não restringe ninguém: quem lê `faça` faz. Palpite continua no disco e
continua achável por busca; ele só não é **injetado** como se fosse sabido.

Os pesos não são gosto. `0.25` é o que faz um instinto de `0.7` **deste** projeto vencer um
global de `0.9` que não tem nada a ver com o que você está fazendo — que é exatamente a
inversão que se quer. E `0.10` para correção do usuário existe porque o que a pessoa te
corrigiu à mão vale mais que o que você inferiu sozinho.

## Os números, e por que estes

| Parâmetro | Valor | Se mudar |
|---|---|---|
| Piso | `0.5` | mais baixo injeta palpite; mais alto perde instinto novo, que nasce em `0.5` |
| Teto | `12` | ~1.200 chars. Acima disso a memória compete com a tarefa |
| Bônus de projeto | `0.25` | abaixo disso o global sempre vence; acima, o global nunca entra |
| Bônus de stack | `0.20` | |
| Bônus de correção | `0.10` | |

## Detecção de stack

Pelo manifesto na raiz, sem adivinhação:

| Achou | Domínios que ganham bônus |
|---|---|
| `package.json` com `react`/`next`/`vue`/`angular`/`svelte` | `ui`, `teste`, `build` |
| `package.json` sem framework de UI | `build`, `teste` |
| `pyproject.toml`, `requirements.txt` | `dados`, `teste` |
| `go.mod`, `pom.xml`, `Cargo.toml` | `build`, `teste` |
| `*.tf`, `docker-compose.yml`, `Dockerfile` | `ferramenta`, `seguranca` |

Nada detectado? Todo bônus de stack é `0` e a ordenação degrada para confiança pura —
comportamento correto, não falha.

## O que a seleção NÃO faz

- Não lê a tarefa. Ela roda antes de existir tarefa; relevância aqui é **lugar e stack**,
  não semântica. Instinto que só o enunciado da tarefa selecionaria é achado por busca, não
  por injeção.
- Não promove escopo. Promoção é ato humano, e `aprender/SKILL.md` diz quando propor.
- Não altera confiança. Quem move a escada é a observação, nunca a leitura.
