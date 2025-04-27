SET search_path TO fh;

CREATE OR REPLACE FUNCTION enunciado4(cargaId integer, navioId integer)
RETURNS TABLE (
	id INTEGER,
	peso REAL,
	produto_id INTEGER,
	porto_id VARCHAR(3),
	navio_id INTEGER
) AS $$
DECLARE 
	navio RECORD;
	navio_carga RECORD;
	carga RECORD;
	categoria RECORD;
	total_carregado integer := 0;
	capacidade_atual integer;
	custo REAL;
BEGIN
	FOR navio_carga IN SELECT * FROM Carga as c where navioId = c.navio_id
	LOOP
		total_carregado := total_carregado + navio_carga.peso;
	END LOOP;

	SELECT * INTO navio 
	FROM Navio as n 
	join Modelo as m ON n.modelo = m.codigo 
	join TipoNavio as tn ON tn.tipo = m.tipo 
	where navioId = n.codigo;
	
	SELECT * INTO carga 
	FROM Carga as c 
	join Produto as p on c.produto_id = p.id 
	join TipoNavioTransporta as tnp on p.categoria_id = tnp.categoria_id
	join CategoriaProduto as cproduct on cproduct.id = p.categoria_id
	where cargaId = c.id and tnp.tipo_navio = navio.tipo;
	
	IF NOT FOUND THEN
	    RAISE NOTICE 'Esse navio não transporta a categoria do produto.';
	    RETURN;
	END IF;

	capacidade_atual := navio.capacidade - total_carregado;

	IF carga.porto_id != navio.porto_id THEN
		RAISE NOTICE 'Navio e carga estão em portos diferentes, carga está no porto de id % e navio no porto de id %', carga.porto_id, navio.porto_id;
		RETURN;
	ELSIF carga.navio_id IS NOT NULL THEN
		RAISE NOTICE 'Carga já está acoplado ao navio de id %.', carga.navio_id;
		RETURN;
	ELSIF capacidade_atual < carga.peso THEN
		RAISE NOTICE 'Navio não tem capacidade sobrando para carregar a carga, capacidade atual do navio é % e peso da carga é %.', capacidade_atual, carga.peso;
		RETURN;
	END IF;

	RAISE NOTICE 'Capacidade atual do navio é % e peso da carga é %', capacidade_atual, carga.peso;

	custo := carga.preco_para_movimentar * carga.peso;

	UPDATE Carga as c
	SET navio_id = navioId
	WHERE c.id = cargaId;
	RAISE NOTICE 'O navio % foi carregado com a carga de id % e com custo %', navio.nome, carga.id, custo;

	RETURN QUERY SELECT carga.id, carga.peso, carga.produto_id, carga.porto_id, navioId;
END
$$ LANGUAGE plpgsql;

select * from enunciado4(7, 4);
