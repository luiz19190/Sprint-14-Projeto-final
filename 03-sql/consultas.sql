-- =============================================================================
-- Sprint 14 — SQL: o mercado de apps de leitura
-- Luiz Trajano
--
-- Todas as consultas do notebook "Sprint 14 - 03 SQL.ipynb", em SQL puro
-- (PostgreSQL). No notebook, os limites ficam em constantes Python
-- (DATA_CORTE, MIN_PAGINAS, MIN_NOTAS, MIN_LIVROS_AVALIADOS); aqui eles
-- aparecem com o valor direto. A numeração segue as seções do notebook.
--
-- Regra da entrega: toda resposta em SQL. Pandas só para mostrar o resultado.
-- A conexão (usuário, senha, host) fica só no notebook da plataforma.
--
-- Conceitos usados, para estudo:
--   AS com o nome da tabela   alias descritivo (books AS books)
--   LEFT JOIN + IS NULL       conta chaves sem par
--   UNION ALL / UNION         empilha resultados (UNION tira repetidos)
--   WITH ... AS (CTE)         agrega cada tabela antes do JOIN
--   COALESCE                  troca NULL por 0 (parecido com fillna)
--   COUNT(*) x COUNT(coluna)  COUNT(coluna) ignora NULL
--   FILTER (WHERE ...)        agregação só nas linhas da condição
--   HAVING x WHERE            HAVING filtra depois do GROUP BY, WHERE antes
--   RANK() / SUM() OVER ()    funções de janela: calculam sem agrupar
--   CASE WHEN                 o "se/senão" do SQL
--   1.0 * / 100.0 *           evita a divisão inteira
--   CORR, ::numeric           correlação de Pearson e conversão de tipo
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 0. Teste da conexão: as 5 tabelas do estudo existem no banco?
-- O banco é compartilhado (12 tabelas), então filtro só as do enunciado.
-- Resultado: authors, books, publishers, ratings, reviews
-- -----------------------------------------------------------------------------
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('books', 'authors', 'publishers', 'ratings', 'reviews')
ORDER BY table_name;


-- -----------------------------------------------------------------------------
-- 2.1 Primeiras linhas e tamanho de cada tabela
-- No notebook, as 5 primeiras consultas saem de um laço pela lista TABELAS.
-- -----------------------------------------------------------------------------
SELECT * FROM books      LIMIT 5;
SELECT * FROM authors    LIMIT 5;
SELECT * FROM publishers LIMIT 5;
SELECT * FROM ratings    LIMIT 5;
SELECT * FROM reviews    LIMIT 5;

-- Um COUNT(*) por tabela, empilhados com UNION ALL; o ORDER BY final ordena tudo.
-- Resultado: ratings 6456, reviews 2793, books 1000, authors 636, publishers 340
SELECT 'books' AS tabela, COUNT(*) AS linhas FROM books
UNION ALL
SELECT 'authors', COUNT(*) FROM authors
UNION ALL
SELECT 'publishers', COUNT(*) FROM publishers
UNION ALL
SELECT 'ratings', COUNT(*) FROM ratings
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
ORDER BY linhas DESC;


-- -----------------------------------------------------------------------------
-- 2.2 Modelo de dados
-- -----------------------------------------------------------------------------

-- Chaves sem par: LEFT JOIN + IS NULL. Zero em todas = ligações íntegras.
-- Resultado: 0, 0, 0, 0
SELECT 'books.author_id -> authors' AS ligacao, COUNT(*) AS sem_par
FROM books AS books
LEFT JOIN authors AS authors ON authors.author_id = books.author_id
WHERE authors.author_id IS NULL

UNION ALL

SELECT 'books.publisher_id -> publishers', COUNT(*)
FROM books AS books
LEFT JOIN publishers AS publishers ON publishers.publisher_id = books.publisher_id
WHERE publishers.publisher_id IS NULL

UNION ALL

SELECT 'ratings.book_id -> books', COUNT(*)
FROM ratings AS ratings
LEFT JOIN books AS books ON books.book_id = ratings.book_id
WHERE books.book_id IS NULL

UNION ALL

SELECT 'reviews.book_id -> books', COUNT(*)
FROM reviews AS reviews
LEFT JOIN books AS books ON books.book_id = reviews.book_id
WHERE books.book_id IS NULL;

-- Notas e resenhas por livro: cada CTE conta uma tabela antes do JOIN.
-- COALESCE põe 0 no livro sem resenha, para ele entrar na média.
-- Resultado: 1000 livros, 1000 com nota, 994 com resenha,
--            6.46 notas/livro (máx. 160), 2.79 resenhas/livro (máx. 7)
WITH notas AS (
    SELECT book_id, COUNT(*) AS n_notas
    FROM ratings
    GROUP BY book_id
),
resenhas AS (
    SELECT book_id, COUNT(*) AS n_resenhas
    FROM reviews
    GROUP BY book_id
)
SELECT
    COUNT(*)                                        AS livros,
    COUNT(notas.book_id)                            AS livros_com_nota,
    COUNT(resenhas.book_id)                         AS livros_com_resenha,
    ROUND(AVG(COALESCE(notas.n_notas, 0)), 2)       AS media_notas_por_livro,
    MAX(notas.n_notas)                              AS max_notas,
    ROUND(AVG(COALESCE(resenhas.n_resenhas, 0)), 2) AS media_resenhas_por_livro,
    MAX(resenhas.n_resenhas)                        AS max_resenhas
FROM books AS books
LEFT JOIN notas AS notas ON notas.book_id = books.book_id
LEFT JOIN resenhas AS resenhas ON resenhas.book_id = books.book_id;

-- Prova da armadilha: o JOIN direto combina cada nota com cada resenha do livro.
-- Resultado: 6456 notas, 2793 resenhas, 26167 linhas no JOIN direto
SELECT
    (SELECT COUNT(*) FROM ratings) AS linhas_ratings,
    (SELECT COUNT(*) FROM reviews) AS linhas_reviews,
    (SELECT COUNT(*)
     FROM ratings AS ratings
     JOIN reviews AS reviews ON reviews.book_id = ratings.book_id) AS linhas_join_direto;


-- -----------------------------------------------------------------------------
-- 3.1 Livros publicados após 01/01/2000
-- "Após" = >. Conto à parte quem saiu exatamente na data de corte.
-- Resultado: 819 após (81,9%), 2 na data, 0 sem data, de 1952-12-01 a 2020-03-31
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*) FILTER (WHERE publication_date > '2000-01-01') AS livros_apos_corte,
    COUNT(*) FILTER (WHERE publication_date = '2000-01-01') AS livros_na_data_corte,
    COUNT(*)                                                AS total_livros,
    ROUND(100.0 * COUNT(*) FILTER (WHERE publication_date > '2000-01-01') / COUNT(*), 1) AS pct_apos_corte,
    COUNT(*) - COUNT(publication_date)                      AS livros_sem_data,
    MIN(publication_date)                                   AS data_mais_antiga,
    MAX(publication_date)                                   AS data_mais_recente
FROM books;


-- -----------------------------------------------------------------------------
-- 3.2 Número de resenhas e nota média por livro
-- Cada tabela agregada por livro numa CTE antes do JOIN; LEFT JOIN mantém os
-- 6 livros sem resenha. No notebook, a consulta base fica na variável
-- sql_livros e é reaproveitada no resumo abaixo.
-- Resultado (topo): Twilight 7 resenhas, 160 notas, 3.66;
--                   Harry Potter (Azkaban) 6 resenhas, 82 notas, 4.41
-- -----------------------------------------------------------------------------
WITH resenhas AS (
    SELECT book_id, COUNT(*) AS n_resenhas
    FROM reviews
    GROUP BY book_id
),
notas AS (
    SELECT book_id, COUNT(*) AS n_notas, ROUND(AVG(rating), 2) AS nota_media
    FROM ratings
    GROUP BY book_id
)
SELECT
    books.book_id,
    books.title,
    COALESCE(resenhas.n_resenhas, 0) AS n_resenhas,
    notas.n_notas,
    notas.nota_media
FROM books AS books
LEFT JOIN resenhas AS resenhas ON resenhas.book_id = books.book_id
LEFT JOIN notas AS notas ON notas.book_id = books.book_id
ORDER BY n_resenhas DESC, nota_media DESC;

-- Resumo da tabela por livro (a consulta acima vira a CTE por_livro).
-- Resultado: média das médias 3.9 (de 1.5 a 5.0); 44 livros com média 5,
--            nenhum com mais de 4 notas; correlação resenhas x nota = 0.02
WITH por_livro AS (
    WITH resenhas AS (
        SELECT book_id, COUNT(*) AS n_resenhas
        FROM reviews
        GROUP BY book_id
    ),
    notas AS (
        SELECT book_id, COUNT(*) AS n_notas, ROUND(AVG(rating), 2) AS nota_media
        FROM ratings
        GROUP BY book_id
    )
    SELECT
        books.book_id,
        books.title,
        COALESCE(resenhas.n_resenhas, 0) AS n_resenhas,
        notas.n_notas,
        notas.nota_media
    FROM books AS books
    LEFT JOIN resenhas AS resenhas ON resenhas.book_id = books.book_id
    LEFT JOIN notas AS notas ON notas.book_id = books.book_id
)
SELECT
    COUNT(*)                                        AS livros,
    ROUND(AVG(nota_media), 2)                       AS media_das_notas_medias,
    MIN(nota_media)                                 AS menor_nota_media,
    MAX(nota_media)                                 AS maior_nota_media,
    COUNT(*) FILTER (WHERE nota_media = 5)          AS livros_nota_5,
    MAX(n_notas) FILTER (WHERE nota_media = 5)      AS max_notas_entre_nota_5,
    ROUND(CORR(n_resenhas, nota_media)::numeric, 2) AS corr_resenhas_nota
FROM por_livro;


-- -----------------------------------------------------------------------------
-- 3.3 Editora com mais livros de mais de 50 páginas (excluindo folhetos)
-- "Mais de 50" = >. Cada publisher_id contado como está no banco
-- (variações de nome, como Ace / Ace Books, não foram agrupadas).
-- -----------------------------------------------------------------------------

-- Tamanho do corte e base de editoras.
-- Resultado: 8 folhetos, 992 livros acima do corte, 340 editoras,
--            334 com livro acima do corte, 2.97 livros por editora
SELECT
    COUNT(*) FILTER (WHERE num_pages <= 50)                     AS folhetos_excluidos,
    COUNT(*) FILTER (WHERE num_pages > 50)                      AS livros_acima_do_corte,
    COUNT(DISTINCT publisher_id)                                AS editoras,
    COUNT(DISTINCT publisher_id) FILTER (WHERE num_pages > 50)  AS editoras_acima_do_corte,
    ROUND(1.0 * COUNT(*) FILTER (WHERE num_pages > 50)
              / COUNT(DISTINCT publisher_id) FILTER (WHERE num_pages > 50), 2) AS media_livros_por_editora
FROM books;

-- Ranking: RANK() mostra empates; SUM() OVER () soma a coluna inteira sem agrupar.
-- As janelas são calculadas antes do LIMIT, então a % é sobre todas as editoras.
-- Resultado: 1 Penguin Books 42 (4.23%), 2 Vintage 31 (3.13%),
--            3 Grand Central Publishing 25 (2.52%), 4 Penguin Classics 24 (2.42%),
--            5 Ballantine Books 19 (1.92%)
WITH por_editora AS (
    SELECT
        publishers.publisher_id,
        publishers.publisher,
        COUNT(*) AS livros
    FROM books AS books
    JOIN publishers AS publishers ON publishers.publisher_id = books.publisher_id
    WHERE books.num_pages > 50
    GROUP BY publishers.publisher_id, publishers.publisher
)
SELECT
    RANK() OVER (ORDER BY livros DESC)             AS posicao,
    publisher,
    livros,
    ROUND(100.0 * livros / SUM(livros) OVER (), 2) AS pct_dos_livros
FROM por_editora
ORDER BY livros DESC
LIMIT 5;


-- -----------------------------------------------------------------------------
-- 3.4 Autor com a maior nota média (só livros com pelo menos 50 notas)
-- "Pelo menos 50" = >= no HAVING. nota_media = média de todas as notas do autor
-- (cada nota pesa igual); media_das_medias só para conferir o primeiro lugar.
-- -----------------------------------------------------------------------------

-- Quantos livros e autores passam no filtro.
-- Resultado: 19 livros, 14 autores
WITH livros_50 AS (
    SELECT
        book_id,
        COUNT(*)    AS n_notas,
        SUM(rating) AS soma_notas,
        AVG(rating) AS nota_media_livro
    FROM ratings
    GROUP BY book_id
    HAVING COUNT(*) >= 50
)
SELECT
    COUNT(*)                        AS livros_com_50_notas,
    COUNT(DISTINCT books.author_id) AS autores
FROM livros_50 AS livros_50
JOIN books AS books ON books.book_id = livros_50.book_id;

-- Ranking dos autores. 1.0 * evita a divisão inteira.
-- Resultado: 1 J.K. Rowling/Mary GrandPré 4.29 (4 livros, 310 notas; média das médias 4.28)
--            2 Markus Zusak/Cao Xuân Việt Khương 4.26 (1 livro, 53 notas)
--            3 J.R.R. Tolkien 4.25 (2 livros, 162 notas)
WITH livros_50 AS (
    SELECT
        book_id,
        COUNT(*)    AS n_notas,
        SUM(rating) AS soma_notas,
        AVG(rating) AS nota_media_livro
    FROM ratings
    GROUP BY book_id
    HAVING COUNT(*) >= 50
)
SELECT
    authors.author,
    COUNT(*)                                                           AS livros,
    SUM(livros_50.n_notas)                                             AS notas,
    ROUND(1.0 * SUM(livros_50.soma_notas) / SUM(livros_50.n_notas), 2) AS nota_media,
    ROUND(AVG(livros_50.nota_media_livro), 2)                          AS media_das_medias
FROM livros_50 AS livros_50
JOIN books AS books     ON books.book_id = livros_50.book_id
JOIN authors AS authors ON authors.author_id = books.author_id
GROUP BY authors.author_id, authors.author
ORDER BY nota_media DESC
LIMIT 5;

-- Achado: os livros do primeiro colocado, sem digitar o nome (ORDER BY + LIMIT 1).
-- Resultado: 4 livros de Harry Potter no filtro (82 + 80 + 75 + 73 = 310 notas);
--            o box 1-5 fica de fora (média 4.50, só 2 notas)
WITH livros_50 AS (
    SELECT
        book_id,
        COUNT(*)    AS n_notas,
        SUM(rating) AS soma_notas,
        AVG(rating) AS nota_media_livro
    FROM ratings
    GROUP BY book_id
    HAVING COUNT(*) >= 50
),
primeiro AS (
    SELECT books.author_id
    FROM livros_50 AS livros_50
    JOIN books AS books ON books.book_id = livros_50.book_id
    GROUP BY books.author_id
    ORDER BY 1.0 * SUM(livros_50.soma_notas) / SUM(livros_50.n_notas) DESC
    LIMIT 1
),
notas_livro AS (
    SELECT book_id, COUNT(*) AS n_notas, ROUND(AVG(rating), 2) AS nota_media
    FROM ratings
    GROUP BY book_id
)
SELECT
    authors.author,
    books.title,
    books.publication_date,
    notas_livro.n_notas,
    notas_livro.nota_media,
    notas_livro.n_notas >= 50 AS passa_filtro
FROM books AS books
JOIN primeiro AS primeiro            ON primeiro.author_id = books.author_id
JOIN authors AS authors              ON authors.author_id = books.author_id
LEFT JOIN notas_livro AS notas_livro ON notas_livro.book_id = books.book_id
ORDER BY notas_livro.n_notas DESC;


-- -----------------------------------------------------------------------------
-- 3.5 Média de resenhas com texto entre usuários que avaliaram mais de 50 livros
-- "Mais de 50" = > com COUNT(DISTINCT book_id). Usuário sem resenha entraria
-- com zero (LEFT JOIN + COALESCE). O outro grupo serve de comparação.
-- -----------------------------------------------------------------------------

-- Quantas resenhas o filtro "com texto" tira.
-- Resultado: 2793 resenhas, 0 sem texto
SELECT
    COUNT(*)                                                AS resenhas,
    COUNT(*) FILTER (WHERE text IS NULL OR TRIM(text) = '') AS resenhas_sem_texto
FROM reviews;

-- Total de usuários: não há tabela de usuários, então uno os username das duas
-- tabelas. UNION (sem ALL) tira os repetidos.
-- Resultado: 160 com nota, 160 com resenha, 160 no total (os mesmos nas duas)
SELECT
    (SELECT COUNT(DISTINCT username) FROM ratings) AS usuarios_com_nota,
    (SELECT COUNT(DISTINCT username) FROM reviews) AS usuarios_com_resenha,
    COUNT(*)                                       AS usuarios_no_total
FROM (
    SELECT username FROM ratings
    UNION
    SELECT username FROM reviews
) AS todos;

-- Média por grupo: CASE WHEN dá nome aos grupos; o PostgreSQL aceita o alias
-- grupo sozinho no GROUP BY e no ORDER BY.
-- Resultado: mais de 50 livros: 6 usuários, 24.33 resenhas (18 a 28), 54.33 livros avaliados
--            50 livros ou menos: 154 usuários, 17.19 resenhas (5 a 29), 39.81 livros avaliados
WITH avaliadores AS (
    SELECT username, COUNT(DISTINCT book_id) AS livros_avaliados
    FROM ratings
    GROUP BY username
),
resenhas AS (
    SELECT username, COUNT(*) AS n_resenhas
    FROM reviews
    WHERE text IS NOT NULL AND TRIM(text) <> ''
    GROUP BY username
)
SELECT
    CASE WHEN avaliadores.livros_avaliados > 50
         THEN 'mais de 50 livros'
         ELSE '50 livros ou menos'
    END                                                 AS grupo,
    COUNT(*)                                            AS usuarios,
    ROUND(AVG(COALESCE(resenhas.n_resenhas, 0)), 2)     AS media_resenhas,
    MIN(COALESCE(resenhas.n_resenhas, 0))               AS min_resenhas,
    MAX(COALESCE(resenhas.n_resenhas, 0))               AS max_resenhas,
    COUNT(*) FILTER (WHERE resenhas.n_resenhas IS NULL) AS usuarios_sem_resenha,
    ROUND(AVG(avaliadores.livros_avaliados), 2)         AS media_livros_avaliados
FROM avaliadores AS avaliadores
LEFT JOIN resenhas AS resenhas ON resenhas.username = avaliadores.username
GROUP BY grupo
ORDER BY grupo DESC;
