# Investigar antes de perguntar

Lido por `demanda` no passo 2. Custo zero. **Tudo aqui é leitura** — nada é criado, alterado
ou executado com efeito.

## No rastreador

- Busque issues com as palavras do pedido no projeto de destino. Achou uma igual ou quase?
  Mostre e pergunte se é para complementar a existente em vez de criar outra.
- Ache o **épico** a que isso pertence. História solta, sem épico, é exceção e deve ser dita.
- Leia os comentários das issues relacionadas: decisões costumam estar lá, não na descrição.

## No código — só com acesso real

Produto costuma ter vários repositórios (front, API, worker, site). 🔴 **Leia todos os do
produto antes de afirmar qualquer coisa sobre o sistema.** Os irmãos estão em
`perfil.tsv:repos_irmaos`; sem a linha, procure os repositórios do produto antes de concluir.
Afirmar que "o frontend não tem tal tela" lendo só a API é o erro que esta regra existe para
impedir.

Para cada capacidade que a demanda toca, registre uma de três:

| Situação | Como escrever |
|---|---|
| já existe | "Já existe: … (visto em `<repositório>`)" |
| não existe | "Ainda não existe: …" |
| não deu para confirmar | vira **pendência** para a engenharia, nunca suposição |

A situação atual vai na história em linguagem de produto. Caminho de arquivo e nome de
função ficam nas suas notas — servem para você ter certeza, não para a história.

## Sem acesso ao código

No chat, sem os repositórios: **não descreva o sistema**. Use o que o rastreador e a pessoa
disseram, com a fonte, e deixe "Situação atual a confirmar pela engenharia" como pendência.
Uma história honesta sobre o que não sabe é melhor que uma confiante e errada.
