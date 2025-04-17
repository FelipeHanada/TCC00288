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
	pilha CHAR(3)[] = ARRAY[]::CHAR(3)[];
	atual_cod CHAR(3) = destino;
	passo INTEGER = 0;
	distancia REAL;
	distancia_acumulada REAL = 0;
BEGIN
	-- EXECUTA DIJKSTRA
	CREATE TEMP TABLE visitados (
		porto CHAR(3) PRIMARY KEY,
		distancia_origem REAL,
		anterior CHAR(3)
	) ON COMMIT DROP;
	
	CREATE TEMP TABLE pq (
		porto CHAR(3) PRIMARY KEY,
		distancia_origem REAL,
		anterior CHAR(3)
	) ON COMMIT DROP;

	INSERT INTO pq VALUES (origem, 0, '000');

	LOOP
        SELECT * INTO atual
        FROM pq
        ORDER BY distancia_origem
        LIMIT 1;
		
		EXIT WHEN NOT FOUND;

		DELETE FROM pq WHERE pq.porto = atual.porto;

		BEGIN
			INSERT INTO visitados VALUES (atual.porto, atual.distancia_origem, atual.anterior);
		EXCEPTION WHEN unique_violation THEN
			CONTINUE;
		END;

		FOR proximo IN
			SELECT p.codigo, r.distancia
			FROM Porto p JOIN Rota r ON (r.destino = p.codigo)
			WHERE r.origem = atual.porto
		LOOP
			IF atual.distancia_origem + proximo.distancia > distancia_maxima THEN
				CONTINUE;
			END IF;
		
			INSERT INTO pq (porto, distancia_origem, anterior)
			VALUES (proximo.codigo, atual.distancia_origem + proximo.distancia, atual.porto)
			ON CONFLICT (porto)
			DO UPDATE SET
			  distancia_origem = EXCLUDED.distancia_origem,
			  anterior = EXCLUDED.anterior
			WHERE pq.distancia_origem > EXCLUDED.distancia_origem;
		END LOOP;
    END LOOP;

	-- RECONSTRUÇÃO DO CAMINHO
	SELECT * INTO atual
		FROM visitados
		WHERE visitados.porto = destino;

	IF NOT FOUND THEN
		RETURN;
	END IF;

	WHILE atual_cod IS NOT NULL AND atual_cod != '000' LOOP
        pilha := array_prepend(atual_cod, pilha);
        SELECT anterior INTO atual_cod
			FROM visitados
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
