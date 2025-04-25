SET search_path TO fh;

CREATE OR REPLACE FUNCTION enunciado1(origem CHAR(3), destino CHAR(3), distancia_maxima REAL DEFAULT 'infinity')
RETURNS TABLE(
	passo INTEGER,
	de CHAR(3),
	para CHAR(3),
	distancia REAL,
	distancia_acumulada REAL
) AS $$
DECLARE
	atual RECORD;
	proximo RECORD;
	proximo_porto RECORD;
	pilha CHAR(3)[] = ARRAY[]::CHAR(3)[];
	atual_cod CHAR(3) = destino;
	passo INTEGER = 0;
	distancia REAL;
	distancia_acumulada REAL = 0;
BEGIN
	-- EXECUÇÃO DIJKSTRA	
	CREATE TEMP TABLE fila_prioridade (
		porto CHAR(3) PRIMARY KEY,
		distancia_origem REAL,
		anterior CHAR(3),
		visitado BOOL DEFAULT FALSE
	) ON COMMIT DROP;
	INSERT INTO fila_prioridade VALUES (origem, 0, NULL, FALSE);

	LOOP
        SELECT * INTO atual
        FROM fila_prioridade
		WHERE visitado = FALSE
        ORDER BY distancia_origem
        LIMIT 1;
		EXIT WHEN NOT FOUND;

		UPDATE fila_prioridade
		SET visitado = TRUE
		WHERE porto = atual.porto;

		FOR proximo_porto IN
			SELECT p.codigo, r.distancia
			FROM Porto p
				JOIN Rota r ON (r.destino = p.codigo)
				LEFT OUTER JOIN fila_prioridade fp ON (fp.porto = p.codigo)
			WHERE
				r.origem = atual.porto
				AND atual.distancia_origem + r.distancia < distancia_maxima
				-- não excede a distância máxima
				AND (
					fp.porto IS NULL OR (
						fp.visitado AND
						atual.distancia_origem + r.distancia < fp.distancia_origem
					)
					-- não é um caminho pior do que outro já encontrado
				)
		LOOP
			INSERT INTO fila_prioridade (porto, distancia_origem, anterior)
			VALUES (proximo_porto.codigo, atual.distancia_origem + proximo_porto.distancia, atual.porto)
			ON CONFLICT (porto)
			DO UPDATE SET
			  distancia_origem = EXCLUDED.distancia_origem,
			  anterior = EXCLUDED.anterior;
		END LOOP;
    END LOOP;

	-- RECONSTRUÇÃO DO CAMINHO
	SELECT * INTO atual
		FROM fila_prioridade
		WHERE fila_prioridade.porto = destino;

	IF NOT FOUND THEN
		RETURN;
	END IF;

	WHILE atual_cod IS NOT NULL AND atual_cod IS NOT NULL LOOP
        pilha := array_prepend(atual_cod, pilha);
        SELECT anterior INTO atual_cod
			FROM fila_prioridade
			WHERE porto = atual_cod;
    END LOOP;

    FOR i IN 1..array_length(pilha, 1) - 1 LOOP
        passo := passo + 1;

        SELECT r.distancia INTO distancia FROM Rota r
		WHERE r.origem = pilha[i] AND r.destino = pilha[i+1];

		distancia_acumulada = distancia_acumulada + distancia;
		
		RETURN QUERY
			SELECT
	            passo,
	            pilha[i],
	            pilha[i+1],
	            distancia,
	            distancia_acumulada;
	END LOOP;
END
$$ LANGUAGE plpgsql;

SELECT * FROM enunciado1('RJ1', 'SHA');
