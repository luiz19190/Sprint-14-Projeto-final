# Sprint 14 — Projeto Final (TripleTen Data Analyst)

Última sprint do bootcamp de Data Analyst da TripleTen. Quatro entregas independentes, cada uma com o próprio notebook:

| # | Entrega | O que é | Status |
|---|---|---|---|
| 1 | [Decomposição](01-decomposicao/) | Plano de análise do Caso Principal (Olist, recompra de clientes) | aprovada |
| 2 | [Teste A/B](02-teste-ab/) | Avaliação do `recommender_system_test` de uma loja virtual (funil + teste Z de proporções) | aprovado |
| 3 | [SQL](03-sql/) | Análise de um banco de livros, autores, editoras, notas e resenhas | aprovado |
| 4 | [Projeto Final](04-projeto-final/) | Implementação da decomposição: notebook, dashboard e apresentação CAR | aprovado |

## Projeto Final: recompra na Olist

O que, na primeira compra, separa o cliente que volta a comprar do que compra uma vez só. Coorte de 58.139 pessoas com a primeira compra entre 01/01/2017 e 04/03/2018; recompra é outro pedido, em outro dia, em até 180 dias.

- Só 2,01% das pessoas da coorte voltaram em até 180 dias.
- O atraso derruba a nota (75,63% de nota de 1 a 3 com atraso, contra 18,17% no prazo), e quem dá nota 1 volta menos (1,68% contra 2,10%).
- O peso do frete não separa quem volta; por estado, só SP (acima) e "outros" (abaixo) diferem do resto.
- Em pessoas, o efeito é pequeno: sem o atraso, cerca de 19 pessoas a mais teriam voltado (1,62% das 1.167 recompras). Por isso a recomendação de cortar o atraso se apoia na experiência do cliente, e não no ganho direto de recompra.

**Materiais:** [dashboard no Tableau Public](https://public.tableau.com/views/RecompraOlist-ProjetoFinal/Painel1?:language=pt-BR&:showVizHome=no&:display_count=n&:origin=viz_share_link) · [apresentação em PDF](04-projeto-final/relatorio/Recompra%20na%20Olist.pdf)

## Estrutura

```
01-decomposicao/   notebook da decomposição + images/
02-teste-ab/       notebook do A/B + data/ (4 CSVs) + images/
03-sql/            notebook SQL (roda só na plataforma) + consultas.sql
04-projeto-final/  notebook + data/ (4 CSVs da Olist) + images/ + dashboard/ + relatorio/
```

Os dados da Olist vêm do [Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce); o notebook lê a cópia local em `data/` e, se ela não existir, o link do Kaggle.

**Ferramentas:** Python (pandas, matplotlib, seaborn, scipy, statsmodels), PostgreSQL, Jupyter, Tableau Public.

**Autor:** Luiz Trajano · [GitHub](https://github.com/luiz19190) · [LinkedIn](https://linkedin.com/in/luiz-antonio-trajano)
