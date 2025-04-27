CREATE OR REPLACE FUNCTION enunciado3a(codigo_porto VARCHAR(3))
RETURNS TABLE(
	id INTEGER,
	peso REAL,
	produto_id INTEGER,
	porto_id VARCHAR(3),
	navio_id INTEGER,
	status TEXT
) AS $$
BEGIN
	RETURN QUERY
	
	SELECT
	Carga.id,
	Carga.peso,
	Carga.produto_id,
	Carga.porto_id,
	Carga.navio_id,
	CASE
		WHEN Carga.navio_id IS NULL THEN 'Armazenada' ELSE 'Em movimento'
	END AS status
	
	FROM fh.Carga
	WHERE Carga.porto_id = codigo_porto;
	
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION enunciado3b(navio_id INTEGER, codigo_porto VARCHAR(3))
RETURNS TABLE (
	carga_id INTEGER,
	carga_peso REAL
) AS $$
DECLARE
	carga RECORD;
	navio RECORD;

	navio_carga RECORD;
	total_carregado INTEGER := 0;
	capacidade INTEGER;

	dp_record RECORD;
BEGIN
	SELECT * INTO navio
	FROM Navio n
		JOIN Modelo m ON (n.modelo = m.codigo)
		JOIN TipoNavio tn ON (m.tipo = tn.tipo)
	WHERE n.codigo = navio_id;

	FOR navio_carga IN SELECT * FROM Carga c where navio.codigo = c.navio_id
	LOOP
		total_carregado := total_carregado + navio_carga.peso;
	END LOOP;
	capacidade := navio.capacidade - total_carregado;

	RAISE NOTICE 'navio capacidade: %', navio.capacidade;
	RAISE NOTICE 'capacidade: %', capacidade;

	CREATE TEMP TABLE dp (
		peso_corrente INTEGER PRIMARY KEY,
		carga_id INTEGER,
		carga_peso REAL
	) ON COMMIT DROP;
	INSERT INTO dp (peso_corrente, carga_id, carga_peso) VALUES (0, NULL, NULL);

	FOR carga IN
		SELECT c.id, c.peso
		FROM TipoNavioTransporta tnt
			JOIN CategoriaProduto cpr ON (tnt.categoria_id = cpr.id)
			JOIN Produto p ON (cpr.id = p.categoria_id)
			JOIN Carga c ON (c.produto_id = p.id)
		WHERE
			navio.tipo = tnt.tipo_navio
			AND c.porto_id = codigo_porto
	LOOP
		RAISE NOTICE 'verificando carga % com peso %', carga.id, carga.peso;
	
		FOR dp_record IN
			SELECT *
			FROM dp dp1
			WHERE
				dp1.peso_corrente + carga.peso <= capacidade
				AND dp1.peso_corrente + carga.peso NOT IN (
					SELECT dp2.peso_corrente
					FROM dp dp2
				) -- não existe uma entrada com chave primária peso_corrente + peso
			ORDER BY dp1.peso_corrente DESC
		LOOP

			RAISE NOTICE 'adicionando';
			INSERT INTO dp VALUES (dp_record.peso_corrente + carga.peso, carga.id, carga.peso);
		
		END LOOP;
	END LOOP;

	SELECT * INTO dp_record
	FROM dp
	ORDER BY peso_corrente DESC
	LIMIT 1;

	WHILE dp_record.carga_id IS NOT NULL
	LOOP
		RETURN QUERY SELECT dp_record.carga_id, dp_record.carga_peso;

		SELECT * INTO dp_record
		FROM dp
		WHERE peso_corrente = dp_record.peso_corrente - dp_record.carga_peso;
	END LOOP;
END
$$ LANGUAGE plpgsql;


SELECT * FROM enunciado3a('SHA');
SELECT * FROM enunciado3b(4, 'SHA');
