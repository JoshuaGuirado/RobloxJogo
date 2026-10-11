# 🦸 Roube um Herói

Jogo completo para Roblox no estilo "roube um personagem", com o tema **heróis**.

Heróis saem de um portal e andam por uma passarela. Você compra os que conseguir, eles ficam na sua base gerando dinheiro, e você pode **roubar os heróis da base dos outros jogadores**, ou se defender com a **Luva Heroica**.

## O que o jogo tem

| | |
|---|---|
| 🏙️ **Cenário completo** | Cidade com 70 prédios neon, praça, ruas, árvores, postes, letreiro gigante, portais com partículas, ciclo de dia e noite, iluminação com brilho e atmosfera |
| 🦸 **36 heróis de filme** | 8 raridades (Comum → SECRETO). Inspirados nos super-heróis do cinema (aranha, morcego, armadura, trovão, lanterna verde...), com nomes próprios. Cada um tem máscara, capacete, capa, emblema e arma/poder. Os raros brilham, o Divino tem auréola e o Secreto tem aura |
| ✨ **Mutações** | Ouro (x2), Diamante (x3), Arco-íris (x5, muda de cor), Cósmico (x10, com partículas) |
| 💰 **Economia** | Renda por segundo, dinheiro acumulado nos pedestais (pise no botão verde para coletar), venda, renda offline |
| 🦹 **Roubo** | Segure E para roubar, carregue o herói (você fica mais lento e marcado em vermelho) e uma seta mostra o caminho até a sua base |
| 🏢 **Bases de 3 andares** | Prédio com 3 andares, elevador de vidro, janelas, luzes, letreiro no telhado e até 24 pedestais |
| 🥊 **Luva Heroica** | Uma luva de boxe 3D de verdade na mão. 5 luvas (Básica, Ferro, Turbo, Trovão, Cósmica): cada uma soca mais forte, mais longe e deixa o ladrão tonto por mais tempo |
| 🎪 **Tenda da Loja** | Uma tenda listrada no meio do mapa com vendedor. Vá até lá para comprar luvas, a **Mola Turbo** (mais velocidade e pulo), mais pedestais, tranca reforçada e coletor automático |
| 🎡 **Roleta da Sorte** | Roleta gigante no mapa: gire de graça a cada 12 horas e ganhe moedas, renda 2x, super velocidade ou até um herói Épico/Lendário |
| 🔒 **Defesa da base** | Tranca com barreira laser que expulsa quem está dentro |
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

Se preferir colar os scripts num lugar que você já tem, crie estes 6 scripts **com estes nomes exatos**:

| Onde criar no Explorador | Tipo | Nome | Arquivo |
|---|---|---|---|
| `ReplicatedStorage` | **ModuleScript** | `ConfigHerois` | `src/ReplicatedStorage/ConfigHerois.lua` |
| `ServerScriptService` | **ModuleScript** | `Mapa` | `src/ServerScriptService/Mapa.lua` |
| `ServerScriptService` | **ModuleScript** | `Dados` | `src/ServerScriptService/Dados.lua` |
| `ServerScriptService` | **ModuleScript** | `ModelosHerois` | `src/ServerScriptService/ModelosHerois.lua` |
| `ServerScriptService` | **Script** | `JogoHerois` | `src/ServerScriptService/JogoHerois.server.lua` |
| `StarterPlayer` → `StarterPlayerScripts` | **LocalScript** | `InterfaceHerois` | `src/StarterPlayerScripts/InterfaceHerois.client.lua` |

Para cada um:
1. Passe o mouse no lugar indicado, clique no **+** e escolha o tipo certo.
2. Renomeie com F2 usando o nome da tabela. O nome precisa ser exatamente igual.
3. Apague o conteúdo padrão e cole o conteúdo do arquivo.

Se você tinha os scripts da versão antiga (`JogoRoubo` e `RouboCliente`), **apague-os**.

### Atualizando um jogo que já está publicado

Não precisa criar um jogo novo. No mesmo lugar do Studio:
1. Abra cada script que mudou, apague tudo (Ctrl+A, Delete) e cole a versão nova.
2. Se faltar algum script da tabela acima (por exemplo o `ModelosHerois`), crie ele.
3. **Arquivo → Publicar no Roblox**. Os jogadores mantêm o progresso: heróis da versão antiga viram os heróis novos automaticamente.

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
  - `!heroi HeroiSupremo Cosmico` → solta um herói específico no portal
  - `!roleta` → libera a roleta de novo na hora (para testar)

---

## Como jogar

| Ação | Como fazer |
|---|---|
| Comprar | Perto de um herói na passarela, aperte **E** |
| Coletar dinheiro | Pise no **botão verde** em frente ao pedestal |
| Roubar | Na base de outro jogador, **segure E** perto de um herói e corra para a sua base |
| Socar | Equipe a **Luva Heroica** (tecla **1**) e clique. Quem leva soco derruba o herói que está roubando |
| Comprar luvas e a Mola | Vá até a **tenda da Loja** (ou clique em 🎪 Loja e siga a luz verde) e aperte **E** no balcão |
| Girar a roleta | Vá até a **roleta gigante** e aperte **E** no botão rosa. Libera a cada 12 horas |
| Trocar de andar | Na sua base, entre no **elevador** de vidro: **E** sobe, **R** desce |
| Vender | Na sua base, aperte **F** perto do herói (devolve 50%) |
| Trancar a base | Pise no **botão verde redondo** da entrada da sua base |

## Heróis

| Raridade | Heróis | Preço | Renda |
|---|---|---|---|
| Comum | Formiga Atômica, Flecha Certeira, Rei dos Mares, Agente Sombra, Pássaro Vermelho, Asa de Aço | $25 – $180 | $1 – $6/s |
| Incomum | Pantera Real, Mago Supremo, Ciborgue Max, Garra Selvagem, Mercenário Tagarela, Senhora Tempestade | $300 – $1,2K | $10 – $36/s |
| Raro | Olho Laser, Garota Invisível, Chama Viva, Gigante de Pedra, Androide Rubro, Corvo Místico | $2K – $8,5K | $60 – $210/s |
| Épico | Bruxa Rubi, Capitã Cósmica, Lanterna Esmeralda, Gata Noturna, Lorde Galáctico | $15K – $58K | $350 – $1,05K/s |
| Lendário | Aranha Escarlate, Cavaleiro Morcego, Capitão Estrela, Raio Veloz, Simbionte Sombrio | $100K – $350K | $1,6K – $4,5K/s |
| Mítico | Titã Esmeralda, Guardião do Trovão, Amazona Dourada, Capitão Relâmpago | $700K – $2M | $8K – $20K/s |
| Divino | Armadura Rubi, Fênix Cósmica | $5M – $8M | $45K – $70K/s |
| SECRETO | Herói Supremo, Viajante de Prata | $25M – $50M | $200K – $380K/s |

> Os heróis são **inspirados** nos filmes, mas têm nomes e visuais próprios. Usar nomes e personagens oficiais (Homem-Aranha, Batman...) pode fazer o Roblox remover o jogo por direitos autorais.

---

## Como personalizar

Quase tudo se muda no **`ConfigHerois`**, sem mexer na lógica:

- **Novo herói:** copie uma linha de `Config.Herois` e troque `id`, `nome`, `raridade`, `preco`, `renda`, `icone` e a tabela `visual` (cores, cabeça, rosto, emblema, capa e o que ele segura).
- **Luvas e roleta:** `Config.Luvas` (preço, força, alcance, recarga) e `Config.Roleta` (prêmios, chances e intervalo).
- **Música de fundo:** na Caixa de ferramentas → **Áudio**, escolha uma música, clique com o botão direito → **Copiar ID do recurso**, e cole em `Config.Sons.Musica = "rbxassetid://NUMERO"`.
- **Preços das melhorias, renascimento, prêmio diário, eventos, mutações e chances:** cada um tem sua seção comentada.
- **Robux:** crie o Game Pass e os Produtos no Creator Dashboard e cole os IDs em `Config.Robux`. Com ID `0` a oferta fica escondida.

## Como o código funciona

```
ReplicatedStorage/ConfigHerois      → configurações (lidas pelo servidor e pela interface)
ServerScriptService/Mapa            → constrói a cidade, a passarela, as bases de 3 andares, a tenda e a roleta
ServerScriptService/Dados           → salva e carrega (DataStore) + ranking global
ServerScriptService/ModelosHerois   → monta o 3D dos 36 heróis, das luvas e da mola
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
