## Como rodar

```bash
bundle install
bundle exec rspec
```

## Parte 2 — Cenário & tecnologias (curta)

### 1- API REST: como você exporia esse pedido como uma API Rails? Quais endpoints, verbos e status codes você usaria para criar, consultar e fazer o pedido transitar de estado? Onde moraria a lógica que você fez na Parte 1?
R - Em uma API Rails iria expor esses dados através de endpoints definidos em controllers, basicamente teriamos o controller orders_controller.rb e o model order.rb. Criaria os seguintes endpoints:
- `POST /orders` — cria um novo pedido
  - status code: 201 Created e 422 Unprocessable Entity
- `GET /orders/:id` — consulta um pedido específico
  - status code: 200 OK e 404 Not Found
- `PATCH /orders/:id/transition` — atualiza o estado de um pedido
  - status code: 200 OK e 404 Not Found || 422 Unprocessable Entity

A lógica da Parte 1 ficaria no model `order.rb`. Uma gem muito usada para controlar a maquina de estados e a state_machines.

### 2- Como uma tela em Vue consumiria essa API para listar os pedidos e disparar uma transição? Que componente(s) você criaria?
R - Criaria os componentes OrderList, OrderPage e TransitionButton. O `OrderList` faria um `GET /orders` ao montar o componente para carregar a lista. O `OrderPage` exibiria os dados de cada pedido e, ao clicar num botão de ação, faria um `PATCH /orders/:id/transitions` enviando o evento no corpo da requisição. Na resposta, atualizaria os dados da page diretamente com o novo status retornado pelo backend.


## 3- e se a validação no provedor demorasse minutos (chamada externa lenta)? Como você trataria isso (ex.: jobs assíncronos)?
R - Utilizaria jobs para fazer o processamento em background. Poderiamos atualizar a order para o status `validating` e enfiler um job, utilizando o Sidekiq ou o SolidQueue, este job validaria a order com o provedor e atualizaria o status de acordo com o resultado. Caso, o job falhe, podemos ter uma estrategia de retry para tentar novamente em caso de falha. E para ser ainda mais seguro, poderiamos ter uma job que roda periodicamente para validar as orders que estão com status `validating` e nao foram atualizadas por algum motivo, como por exemplo, o status nao foi atualizado mesmo com a resposta positiva do provedor(erro ao transicionar o estado).
