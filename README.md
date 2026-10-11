# Roube um Personagem 🕵️

Jogo para Roblox no estilo "roube um personagem". Personagens engraçados passam por uma passarela, você compra os que conseguir, eles ficam na sua base gerando dinheiro, e você pode **roubar** os personagens da base dos outros jogadores.

O script **monta o mapa sozinho**: a passarela, 6 bases com paredes, os pedestais, as placas e os botões de trancar. Você só precisa colar 2 scripts.

## Arquivos

| Arquivo | Onde colocar no Roblox Studio | Tipo |
|---|---|---|
| `src/ServerScriptService/JogoRoubo.server.lua` | `ServerScriptService` | **Script** |
| `src/StarterPlayerScripts/RouboCliente.client.lua` | `StarterPlayer` → `StarterPlayerScripts` | **LocalScript** |

---

## Passo a passo para montar

### 1. Crie o lugar
1. Abra o **Roblox Studio**.
2. Clique em **Novo** → **Baseplate**.

### 2. Script do servidor
1. No **Explorador** (à direita), passe o mouse em **ServerScriptService** e clique no **+**.
2. Escolha **Script**.
3. Renomeie para `JogoRoubo` (clique com o botão direito → Renomear, ou F2).
4. Apague o `print("Hello world!")`.
5. Copie **todo** o conteúdo de `src/ServerScriptService/JogoRoubo.server.lua` e cole no script.

### 3. Script do jogador
1. No Explorador, clique na setinha ao lado de **StarterPlayer** para abrir.
2. Passe o mouse em **StarterPlayerScripts** → **+** → **LocalScript** (atenção: é *Local*Script).
3. Renomeie para `RouboCliente`.
4. Apague o conteúdo e cole o de `src/StarterPlayerScripts/RouboCliente.client.lua`.

### 4. Teste sozinho
1. Aperte **▶ Jogar** (F5).
2. Você vai aparecer dentro da sua base. Ande até a passarela vermelha.
3. Chegue perto de um personagem e aperte **E** para comprar. Você começa com $100.
4. O personagem vai sozinho para a sua base e começa a render dinheiro por segundo.

### 5. Teste o roubo (com 2 jogadores)
1. Vá na aba **Teste**.
2. No campo de clientes, escolha **2 jogadores** e clique em **Iniciar**. Abrem 3 janelas: o servidor e 2 jogadores.
3. Com o jogador 1, compre um personagem.
4. Com o jogador 2, entre na base do jogador 1, chegue perto do personagem e **segure E** para roubar.
5. Leve o personagem de volta para a sua base. Se o dono encostar em você no caminho, o personagem volta para ele!
6. Para parar o teste, clique em **Limpar** na aba Teste.

### 6. Publique
**Arquivo → Publicar no Roblox**. Depois, em **Configurações do jogo → Permissões**, deixe o jogo **Público**.

---

## Como jogar

| Ação | Como fazer |
|---|---|
| Comprar | Perto de um personagem na passarela, aperte **E** |
| Roubar | Na base de outro jogador, **segure E** perto de um personagem |
| Entregar o roubo | Entre na **sua** base carregando o personagem |
| Recuperar | Encoste no ladrão antes que ele chegue na base dele |
| Vender | Na sua base, aperte **F** perto do personagem (devolve 50%) |
| Trancar a base | Pise no **botão verde** da sua base: uma barreira laser bloqueia os outros por 60s |

Regras:
- Cada base tem **8 pedestais**. Com a base cheia, você precisa vender um personagem para comprar ou roubar outro.
- Quem carrega um personagem roubado fica **mais lento**.
- Se o ladrão morrer, o personagem volta para o dono.
- Base trancada não pode ser roubada.

## Personagens

| Personagem | Raridade | Preço | Renda |
|---|---|---|---|
| Batatinha Saltitante | Comum | $25 | $1/s |
| Chinelo Voador | Comum | $40 | $2/s |
| Pato de Gravata | Raro | $150 | $6/s |
| Melancia Ninja | Raro | $250 | $10/s |
| Sapo Astronauta | Épico | $1.000 | $35/s |
| Pizza Dançarina | Épico | $1.500 | $50/s |
| Tubarão de Tênis | Lendário | $5.000 | $150/s |
| Capivara Rei | Lendário | $8.000 | $250/s |
| Dragão de Pijama | Mítico | $25.000 | $700/s |
| Bigodudo Supremo | SECRETO | $100.000 | $2.500/s |

Quanto mais rara, mais difícil de aparecer, maior o personagem, e os Lendários para cima brilham.

---

## Como personalizar

Tudo fica no começo do `JogoRoubo`:

- **`CONFIG`**: dinheiro inicial, velocidade da passarela, tempo de tranca, porcentagem de venda etc.
- **`PERSONAGENS`**: para criar um personagem novo, copie uma linha e mude nome, raridade, preço, renda e cor:
  ```lua
  { nome = "Gato de Óculos", raridade = "Raro", preco = 200, renda = 8, cor = Color3.fromRGB(255, 140, 0) },
  ```
- **`RARIDADES`**: a `chance` controla quantas vezes cada raridade aparece.
- **`POSICOES_BASES`**: adicione posições para ter mais bases (1 base por jogador).

## Como o código funciona (resumo)

1. **Mapa**: `construirBase` cria o chão, as paredes, a barreira, a placa, o botão e os 8 pedestais de cada base, tudo com `Instance.new("Part")`.
2. **Jogador entra** (`aoEntrar`): ganha a `leaderstats` com o Dinheiro, recebe uma base livre e um HUD na tela. Toda vez que nasce, é levado para dentro da própria base.
3. **Passarela**: a cada 3s, `criarPersonagem` monta um boneco (corpo, cabeça, olhos e pernas) com um `ProximityPrompt` de compra. O `Heartbeat` move os bonecos até o fim da passarela.
4. **Compra** (`aoComprar`): confere dinheiro e pedestal livre, desconta o preço e usa o `TweenService` para levar o boneco até a base.
5. **Renda**: um loop a cada 1 segundo soma a renda dos personagens de cada base e paga o dono.
6. **Roubo** (`aoRoubar`): o boneco é soldado (`WeldConstraint`) em cima da cabeça do ladrão. A cada frame, `verificarCarregado` checa se ele chegou na própria base (`entregar`) ou se o dono encostou nele (`devolver`).
7. **Tranca**: usa *Collision Groups*. A barreira colide com todo mundo, menos com o dono da base.
8. **Cliente** (`RouboCliente`): esconde o botão "Roubar" nos seus personagens e o botão "Vender" nos personagens dos outros.

## Problemas comuns

- **Nada aparece no mapa**: confira se o script está em `ServerScriptService` e se é um **Script** (não um LocalScript). Abra **Janela → Saída** para ver erros em vermelho.
- **Aparece "Roubar" nos meus próprios personagens**: o `RouboCliente` não está em `StarterPlayerScripts`, ou foi criado como Script em vez de LocalScript.
- **O dinheiro não salva quando saio**: isso ainda não foi feito. O próximo passo seria usar o `DataStoreService`.
