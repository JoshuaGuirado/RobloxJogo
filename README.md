# 🦸 Roube um Herói

Jogo completo para Roblox no estilo "roube um personagem", com o tema **heróis**.

Heróis saem de um portal e andam por uma passarela. Você compra os que conseguir, eles ficam na sua base gerando dinheiro, e você pode **roubar os heróis da base dos outros jogadores**, ou se defender com a **Luva Heroica**.

## O que o jogo tem

| | |
|---|---|
| 🏙️ **Cenário completo** | Cidade com 70 prédios neon, praça, ruas, árvores, postes, letreiro gigante, portais com partículas, ciclo de dia e noite, iluminação com brilho e atmosfera |
| 🦸 **24 heróis originais** | 8 raridades (Comum → SECRETO). Cada herói tem capa, emblema e acessório (máscara, capacete, coroa ou antena). Os raros brilham, o Divino tem auréola e o Secreto tem aura |
| ✨ **Mutações** | Ouro (x2), Diamante (x3), Arco-íris (x5, muda de cor), Cósmico (x10, com partículas) |
| 💰 **Economia** | Renda por segundo, dinheiro acumulado nos pedestais (pise no botão verde para coletar), venda, renda offline |
| 🦹 **Roubo** | Segure E para roubar, carregue o herói (você fica mais lento e marcado em vermelho) e uma seta mostra o caminho até a sua base |
| 🥊 **Defesa** | Luva Heroica: o soco empurra e faz o ladrão derrubar o herói. Tranca com barreira laser que expulsa quem está dentro |
| 🛒 **Loja** | Botas Turbo (velocidade), Mais Pedestais (6 → 12), Tranca Reforçada, Coletor Automático |
| ♻️ **Renascimento** | Recomeça com +50% de renda para sempre |
| 🎁 **Prêmio diário** | Sequência de 7 dias, e o dia 7 vale o dobro |
| 📖 **Índice** | Coleção de todos os heróis descobertos |
| 🏆 **Ranking** | 3 quadros gigantes no mapa (mais ricos, maiores ladrões, renascimentos), ranking global salvo e aba do servidor. O mais rico do servidor ganha uma coroa 👑 |
| ⚡ **Eventos** | A cada 7 minutos: Hora Dourada, Invasão Lendária, Chuva de Heróis ou Renda em Dobro |
| 💾 **Salvamento** | Dinheiro, heróis, melhorias, Índice e estatísticas ficam salvos (DataStore) |
| 🎨 **Interface profissional** | Tela de abertura, contador de dinheiro animado, menus com animação, notificações, anúncios, alarme quando te roubam, tutorial para iniciantes, confete, funciona no celular |
| 💎 **Robux (opcional)** | Game Pass de dinheiro em dobro e pacotes de moedas |

---

## Como montar (jeito fácil: abrir o arquivo pronto)

1. Baixe o arquivo **`RoubeUmHeroi.rbxlx`** deste repositório. No GitHub, clique no arquivo e depois no botão de download.
2. Dê dois cliques no arquivo, ou no Roblox Studio vá em **Arquivo → Abrir do arquivo**.
3. Aperte **▶ Jogar**. O mapa inteiro é construído automaticamente quando o jogo começa.

> No modo de edição o mundo fica vazio. Isso é normal: a cidade aparece quando você aperta **Jogar**.

## Como montar (copiando os scripts)

Se preferir colar os scripts num lugar que você já tem, crie estes 5 scripts **com estes nomes exatos**:

| Onde criar no Explorador | Tipo | Nome | Arquivo |
|---|---|---|---|
| `ReplicatedStorage` | **ModuleScript** | `ConfigHerois` | `src/ReplicatedStorage/ConfigHerois.lua` |
| `ServerScriptService` | **ModuleScript** | `Mapa` | `src/ServerScriptService/Mapa.lua` |
| `ServerScriptService` | **ModuleScript** | `Dados` | `src/ServerScriptService/Dados.lua` |
| `ServerScriptService` | **Script** | `JogoHerois` | `src/ServerScriptService/JogoHerois.server.lua` |
| `StarterPlayer` → `StarterPlayerScripts` | **LocalScript** | `InterfaceHerois` | `src/StarterPlayerScripts/InterfaceHerois.client.lua` |

Para cada um:
1. Passe o mouse no lugar indicado, clique no **+** e escolha o tipo certo.
2. Renomeie com F2 usando o nome da tabela. O nome precisa ser exatamente igual.
3. Apague o conteúdo padrão e cole o conteúdo do arquivo.

Se você tinha os scripts da versão antiga (`JogoRoubo` e `RouboCliente`), **apague-os**.

### Recomendado
- **Iluminação "Future"** (fica muito mais bonito): selecione **Lighting** no Explorador e, em Propriedades, mude **Technology** para **Future**. O arquivo pronto já vem assim.
- **Máximo de 8 jogadores** (são 8 bases): **Início → Configurações do jogo → Lugares → Máximo de jogadores = 8**.

## Salvar o progresso e o ranking global

O salvamento usa DataStore, que só funciona em jogos **publicados**:

1. **Arquivo → Publicar no Roblox**.
2. **Início → Configurações do jogo → Segurança** → ative **"Permitir acesso do Studio aos serviços de API"**.

Sem isso o jogo funciona normalmente, só não salva. Um aviso aparece na tela e os quadros mostram o ranking do servidor.

## Testando

- **Sozinho:** aperte **▶ Jogar**.
- **Roubo entre jogadores:** aba **Teste** → escolha **2 jogadores** → **Iniciar**.
- **Comandos de teste** (no chat, só no Studio ou para o dono do jogo):
  - `!dinheiro 1000000` → ganha dinheiro
  - `!evento` → começa um evento aleatório. Também dá para escolher: `!evento HoraDourada`
  - `!heroi MestreMultiverso Cosmico` → solta um herói específico no portal

---

## Como jogar

| Ação | Como fazer |
|---|---|
| Comprar | Perto de um herói na passarela, aperte **E** |
| Coletar dinheiro | Pise no **botão verde** em frente ao pedestal |
| Roubar | Na base de outro jogador, **segure E** perto de um herói e corra para a sua base |
| Socar | Equipe a **Luva Heroica** (tecla **1**) e clique. Quem leva soco derruba o herói que está roubando |
| Vender | Na sua base, aperte **F** perto do herói (devolve 50%) |
| Trancar a base | Pise no **botão verde redondo** da entrada da sua base |

## Heróis

| Raridade | Heróis | Preço | Renda |
|---|---|---|---|
| Comum | Garoto Bolha, Garota Mola, Capitão Chinelo, Senhor Pipoca | $25 – $90 | $1 – $4/s |
| Incomum | Ventania, Doutor Gelinho, Faísca, Escudeiro Mirim | $200 – $600 | $8 – $22/s |
| Raro | Trovoada, Lâmina Noturna, Punho de Aço, Sombra Veloz | $1,2K – $3,5K | $40 – $100/s |
| Épico | Capitão Cometa, Fênix Rubra, Guardião Esmeralda | $8K – $18K | $200 – $420/s |
| Lendário | Titã Dourado, Dama do Relâmpago, Coronel Galáxia | $50K – $120K | $1K – $2,2K/s |
| Mítico | Imperador Solar, Rainha Nebulosa | $400K – $650K | $6K – $9K/s |
| Divino | Arcanjo Supremo, Oráculo Eterno | $2M – $3,5M | $25K – $40K/s |
| SECRETO | O Herói Desconhecido, Mestre Multiverso | $15M – $30M | $150K – $280K/s |

---

## Como personalizar

Quase tudo se muda no **`ConfigHerois`**, sem mexer na lógica:

- **Novo herói:** copie uma linha de `Config.Herois` e troque `id`, `nome`, `raridade`, `preco`, `renda`, `icone`, `cabeca` e as cores.
- **Música de fundo:** na Caixa de ferramentas → **Áudio**, escolha uma música, clique com o botão direito → **Copiar ID do recurso**, e cole em `Config.Sons.Musica = "rbxassetid://NUMERO"`.
- **Preços das melhorias, renascimento, prêmio diário, eventos, mutações e chances:** cada um tem sua seção comentada.
- **Robux:** crie o Game Pass e os Produtos no Creator Dashboard e cole os IDs em `Config.Robux`. Com ID `0` a oferta fica escondida.

## Como o código funciona

```
ReplicatedStorage/ConfigHerois      → configurações (lidas pelo servidor e pela interface)
ServerScriptService/Mapa            → constrói a cidade, a passarela, as bases e os quadros
ServerScriptService/Dados           → salva e carrega (DataStore) + ranking global
ServerScriptService/JogoHerois      → regras do jogo (servidor)
StarterPlayerScripts/InterfaceHerois → interface e efeitos (cada jogador)
```

- O **servidor** decide tudo: dinheiro, compras, roubos e melhorias. A interface só **pede** coisas (`RemoteFunction "Acao"`) e o servidor confere antes de aceitar. Isso evita trapaças.
- O servidor manda o estado para a interface por **atributos** do jogador (`Dinheiro`, `RendaPorSegundo`, `NivelVelocidade`...) e por eventos (`Notificar`, `Anuncio`, `Efeito`).
- Cada herói é montado com peças soldadas (`WeldConstraint`) a um tronco. Mover o tronco move o herói inteiro.
- A tranca usa **Collision Groups**: a barreira bloqueia todo mundo, menos o dono da base.

## Para desenvolvedores (Rojo)

O projeto também funciona com [Rojo](https://rojo.space): `rojo serve` para sincronizar com o Studio, ou `rojo build -o RoubeUmHeroi.rbxlx` para gerar o arquivo de lugar.

## Problemas comuns

- **Nada aparece quando aperto Jogar:** abra **Janela → Saída** e veja o erro em vermelho. Normalmente é um script com nome ou tipo errado, como Script em vez de ModuleScript.
- **"Infinite yield possible on ... ConfigHerois":** o ModuleScript `ConfigHerois` não está em `ReplicatedStorage` ou está com outro nome.
- **Aparece "Roubar" nos meus heróis:** o `InterfaceHerois` precisa ser um **LocalScript** em `StarterPlayerScripts`.
- **"Seu progresso NÃO será salvo":** veja a seção *Salvar o progresso*.
