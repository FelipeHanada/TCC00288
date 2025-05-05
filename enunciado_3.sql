SET search_path TO afpg;

DROP TYPE IF EXISTS carga_info CASCADE;
CREATE TYPE carga_info AS (
    id TEXT,
    peso INTEGER
);

CREATE OR REPLACE FUNCTION mochila(navio_id INTEGER, codigo_porto VARCHAR(3))
RETURNS TABLE (
	cargas carga_info[], 
	peso_total INTEGER
) AS $$
DECLARE
	carga RECORD;
	navio RECORD;
	navio_carga RECORD;
	total_carregado INTEGER := 0;
	capacidade_maxima INTEGER;

    pesos INTEGER[];
    ids INTEGER[];
    n INTEGER;
    dp INTEGER[][] := '{}';
    keep BOOLEAN[][] := '{}';
    i INTEGER;
    w INTEGER;
    resultado INTEGER := 0;
    selecionados carga_info[] := '{}';
	linha carga_info;
BEGIN
	SELECT * INTO navio
	FROM Navio n
		JOIN Modelo m ON (n.modelo = m.codigo)
		JOIN TipoNavio tn ON (m.tipo = tn.tipo)
	WHERE n.codigo = navio_id;

	FOR navio_carga IN SELECT * FROM Carga c WHERE navio.codigo = c.navio_id
	LOOP
		total_carregado := total_carregado + navio_carga.peso;
	END LOOP;

	capacidade_maxima := navio.capacidade - total_carregado;

	RAISE NOTICE 'navio capacidade: %', navio.capacidade;
	RAISE NOTICE 'capacidade restante: %', capacidade_maxima;

	capacidade_maxima := capacidade_maxima/100;

	SELECT array_agg(peso/100), array_agg(id)
    INTO pesos, ids
    FROM Carga c
	WHERE c.porto_id = codigo_porto AND c.navio_id IS NULL;

    n := COALESCE(array_length(pesos, 1), 0);
    IF n = 0 OR capacidade_maxima <= 0 THEN
        RETURN;
    END IF;

	dp := array_fill(0, ARRAY[n+1, capacidade_maxima+1], ARRAY[0, 0]);
	keep := array_fill(FALSE, ARRAY[n+1, capacidade_maxima+1], ARRAY[0, 0]);

    FOR i IN 1..n LOOP
        FOR w IN 0..capacidade_maxima LOOP
            IF pesos[i] <= w THEN
 				IF w >= pesos[i] AND dp[i-1][w] < dp[i-1][w - pesos[i]] + pesos[i] THEN
                    dp[i][w] := dp[i-1][w - pesos[i]] + pesos[i];
                    keep[i][w] := true;
                ELSE
                    dp[i][w] := dp[i-1][w];
                END IF;
            ELSE
                dp[i][w] := dp[i-1][w];
            END IF;
        END LOOP;
    END LOOP;

    resultado := dp[n][capacidade_maxima];
    peso_total := resultado;

    w := capacidade_maxima;
    FOR i IN REVERSE n..1 LOOP
        IF keep[i][w] THEN
            linha := ROW(ids[i], pesos[i] * 100);
            selecionados := array_append(selecionados, linha);
            w := w - pesos[i];
        END IF;
    END LOOP;

    cargas := selecionados;

	RETURN QUERY SELECT selecionados, peso_total * 100;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION enunciado3b(codigo_porto VARCHAR(3))
RETURNS TABLE (
    navio_id INTEGER,
    cargas carga_info[], 
    peso_total INTEGER
) AS $$
DECLARE
    navio RECORD;
    cargas carga_info[];
    peso_total INTEGER;
BEGIN
    FOR navio IN
        SELECT n.codigo
        FROM Navio as n
        WHERE n.porto_id = codigo_porto
    LOOP
        SELECT m.cargas, m.peso_total
        INTO cargas, peso_total
        FROM mochila(navio.codigo, codigo_porto) as m
        LIMIT 1;

        RETURN QUERY SELECT navio.codigo, cargas, peso_total;
    END LOOP;
END
$$ LANGUAGE plpgsql;


SELECT * FROM enunciado3b('SHA');
