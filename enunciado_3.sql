CREATE OR REPLACE FUNCTION enunciado3(codigo_porto VARCHAR(3))
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


SELECT * FROM enunciado3('SHA');
