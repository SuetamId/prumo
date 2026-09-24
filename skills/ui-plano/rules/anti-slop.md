# Marcas de UI gerada por modelo — o que evitar e por quê

Lido pelo plano de UI, antes de escrever estilo. Custo residente zero.

## O problema

Todo modelo foi treinado nos mesmos templates de SaaS. Sem direção, todo projeto recebe
o mesmo punhado de tiques — e eles são reconhecíveis. Não é questão de gosto: um produto
que parece gerado perde confiança antes de alguém ler uma linha do conteúdo.

Isto **não** é lista de proibições estéticas. Cada item abaixo tem um porquê funcional, e
a saída legítima é sempre a mesma: **fazer a escolha de propósito e registrá-la** no plano
de UI. O erro não é usar Inter; é usar Inter porque ninguém decidiu nada.

## As marcas

| Marca | Por que denuncia |
|---|---|
| **Inter / Roboto / Arial / system-ui** em tudo | fonte é a decisão de marca mais barata que existe. Não tomá-la é visível |
| **Gradiente roxo→azul** | a assinatura da geração. Gradiente que não sai da paleta da marca não é decisão |
| **Card dentro de card** | dois níveis de elevação para uma hierarquia só. Escolha borda **ou** elevação, não as duas |
| **Cinza puro** (`#000`, `#6b7280`) | cinza sem tinta é o cinza de ninguém. Tinte com a matiz da marca |
| **Texto cinza sobre fundo colorido** | falha contraste quase sempre, e parece rascunho |
| **Quadradinho de ícone arredondado acima de todo heading** | decoração que não carrega informação, repetida até virar ruído |
| **Easing com salto** (bounce/elastic) | marca de 2015. Movimento explica origem e destino; salto chama atenção para si |
| **Glow colorido em sombra** | imita foco e compete com o foco de verdade |
| **Borda lateral em aba/alerta** | o tique de "callout de documentação" colado em produto |

## O que fazer no lugar

- **Tipografia:** escolha uma fonte com intenção declarada. Uma família bem usada vence
  três mal combinadas. Registre a escolha no plano de UI.
- **Cor:** uma paleta derivada de uma matiz. Neutros **tintados** com essa matiz. Cor
  saturada reservada para o que precisa de atenção — se tudo chama atenção, nada chama.
- **Elevação:** um sistema, poucos degraus, aplicado por significado (o que flutua sobre o
  quê), nunca por decoração.
- **Movimento:** teto de 200ms no retorno de interação, easing sem overshoot, e
  `prefers-reduced-motion` respeitado.
- **Densidade:** uma decisão para o produto inteiro, não uma por tela.

## O detector

```bash
bash scripts/detectar-slop.sh <dir>     # 0 limpo · 2 achados · 1 não mediu
```

**11 regras determinísticas**, sem modelo e sem rede — elas leem o código-fonte. Não veem
a tela renderizada, então não medem contraste real, card aninhado depois do CSS cascatear,
nem alvo de toque final. Detector limpo é **evidência, não prova**: a prova continua sendo
`../../prova/rules/prova-de-tela.md`.

Achado não é reprovação automática. Cada um pede julgamento, e a saída legítima é corrigir
**ou** registrar a escolha deliberada no plano de UI.

## Se o Impeccable estiver instalado, ele manda

O [Impeccable](https://github.com/pbakaus/impeccable) é dedicado a isto: 61 regras
determinísticas sobre o **DOM renderizado**, crítica por modelo, e iteração ao vivo no
browser. Nosso detector é o piso para quando ele não está lá — não um concorrente.

```bash
ls .claude/skills/impeccable .cursor/skills/impeccable 2>/dev/null   # está instalado?
```

Instalado → use `/impeccable audit` e `/impeccable critique` no lugar do nosso detector, e
`npx impeccable detect <url>` para o que só existe renderizado. O plano de UI continua
sendo nosso: ele decide **quando** o ofício visual entra e o que conta como pronto.
