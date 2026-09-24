# Mapear a interface atual — o degrau 3 da escada

Lido quando não há protótipo nem referência externa. Custo residente zero.

## O que isto é

Extrair o vocabulário visual que o produto **já usa** e construir dentro dele. Numa base
madura, isso costuma dar resultado melhor que um protótipo solto que ninguém conciliou
com o que existe — consistência é qualidade percebida, e o usuário nota a quebra antes
de notar o refinamento.

## A ordem — cada passo responde uma pergunta do plano

**1. Existe design system?**

```bash
ls node_modules | grep -iE 'ui|design|ds-' ; grep -iE '"[^"]*(ui|design-system|tokens)"' package.json
find . -name '*.tokens.*' -o -name 'tokens.css' -o -name '_variables.scss' | grep -v node_modules | head
```

Achou → ele manda, e os passos seguintes só preenchem o que ele não cobre.

**2. Que tela mais se parece com a que vou construir?**

Procure pelo **papel**, não pelo nome: uma listagem com filtro, um formulário de
cadastro, um detalhe com abas. Ela é o gabarito — copie a estrutura, não o conteúdo.

**3. Qual o vocabulário de espaçamento e tipografia?**

```bash
grep -rhoE '(margin|padding|gap)[^;]*: *[0-9.]+(px|rem)' src --include=*.css --include=*.scss \
  | grep -oE '[0-9.]+(px|rem)' | sort | uniq -c | sort -rn | head -12
```

A escala real do produto é a que aparece — não a que a documentação afirma. Se `8px`,
`16px` e `24px` dominam, essa é a escala. Valor que aparece uma vez é acidente, não padrão.

**4. Que componentes já resolvem as affordances da minha tela?**

Para cada peça do plano (menu, diálogo, tabela, campo, overlay), procure o que o
repositório já usa para o **mesmo papel**:

```bash
grep -rn --include=*.tsx --include=*.vue --include=*.html --include=*.ts \
  -E 'role="(menu|dialog|tab)"|Modal|Dropdown|DataTable|Tooltip' src | cut -d: -f1 | sort -u | head
```

🔴 **Dois resultados com o mesmo papel já é o defeito.** É assim que um produto acaba com
dois menus visualmente diferentes, ambos "certos" por alguma regra. Achou dois? Use o
mais recente e registre a duplicação — não crie o terceiro.

**5. Como o produto trata os estados?**

Ache uma tela que já tem vazio, carregando e erro, e copie o tratamento. Estado é onde
produto sem padrão declarado mais diverge, e onde o usuário mais percebe.

## O que sai disto

O bloco **Componentes** e o bloco **Estados** do plano de UI, preenchidos com evidência:
cada linha cita o arquivo de onde o padrão foi lido. Padrão afirmado sem caminho é
memória, não medição.

## Quando NÃO usar o padrão encontrado

Quando ele está medido como errado — contraste abaixo do mínimo, estado inacessível por
teclado, foco invisível. Consistência não é desculpa para propagar defeito de
acessibilidade: aí vale `qualidade-ui.md`, e a divergência entra no plano com o motivo.
