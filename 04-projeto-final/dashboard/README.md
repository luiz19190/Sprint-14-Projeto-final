# Dashboard do Caso Principal

**Link público:** https://public.tableau.com/views/RecompraOlist-ProjetoFinal/Painel1?:language=pt-BR&:showVizHome=no&:display_count=n&:origin=viz_share_link

A instrução da plataforma trata o dashboard como opcional (link do Tableau Public em `dashboard.txt`); o Notion 2026 trata como obrigatório. Ele está no cronograma da decomposição (0,5 dia), então entra na primeira entrega. Se ficar para depois, avisar na entrega: o projeto só é aceito com ele.

## Requisitos

- Mostra os KPIs analisados no notebook e está ligado à solução proposta.
- Claro e organizado, compreensível para um stakeholder.
- Qualquer ferramenta, desde que o revisor consiga abrir.
- Filtros pelas variáveis relevantes, quando fizer sentido.

## Escolha da ferramenta

| Ferramenta | A favor | Contra |
|---|---|---|
| Tableau Public | Grátis, link público garantido | Tudo publicado fica público |
| Power BI | Conta para a meta PL-300 | "Publicar na Web" exige conta corporativa ou de estudante; com Gmail pessoal o revisor pode não conseguir abrir |
| Looker Studio | Grátis, link com conta Google | Menos alinhado à meta de estudo |

Decisão: **Tableau Public** (decomposição 5.4): abre pelo link, sem conta corporativa, para o revisor e para quem quiser verificar a análise.

## Conteúdo

- `base_dashboard.csv`: exportado pela seção 5.2 do notebook. Os números do dashboard têm de bater com o notebook.
- Mostra (decomposição 5.4): taxa de recompra da coorte e por mês da primeira compra; recompra por atraso, por grupo de nota e por faixa de peso do frete; recompra por estado (mapa ou barras).
- Filtros: mês da primeira compra, grupo de estado, grupo de nota, atrasou (sim ou não).
- Cores: quem voltou em azul `#5B6BF5`, quem não voltou em vermelho `#FF6B6B`, referências em cinza.
- Paleta: fundo escuro `#0d0d0d` e as mesmas cores fixas por grupo do notebook.
