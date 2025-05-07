SET search_path TO afpg;

DROP TYPE IF EXISTS carga_info CASCADE;
CREATE TYPE carga_info AS (
    id TEXT,
    peso INTEGER
);

DROP TYPE IF EXISTS dp_type CASCADE;
CREATE TYPE dp_type AS (
    peso_corrente INTEGER,
	indice INTEGER,
    carga_id INTEGER,
	carga_peso REAL
);

CREATE OR REPLACE FUNCTION busca_binaria(arr dp_type[], alvo INTEGER)
RETURNS INTEGER AS $$
DECLARE
    inicio INTEGER := 1;
    fim INTEGER := array_length(arr, 1);
    meio INTEGER;
BEGIN
    WHILE inicio <= fim LOOP
        meio := (inicio + fim) / 2;

        IF arr[meio].peso_corrente = alvo THEN
            RETURN meio;
        ELSIF arr[meio].peso_corrente < alvo THEN
            inicio := meio + 1;
        ELSE
            fim := meio - 1;
        END IF;
    END LOOP;

    RETURN -1;
END;
$$ LANGUAGE plpgsql;

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

    dp dp_type[] := '{}';
	carga_dp dp_type;
	peso INTEGER := 1;

  	new_peso INTEGER;
  	existe BOOLEAN;
  	entrada dp_type;
    i INTEGER;
    w INTEGER := 0;
    resultado INTEGER := 0;
    selecionados carga_info[] := '{}';
	linha carga_info;
	dp_len INTEGER;
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

    carga_dp := (0, 0, NULL, NULL);

    dp := array_append(dp, carga_dp);

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
		RAISE NOTICE '%', carga;
		w := w + 1;
		dp_len := array_length(dp, 1);
		
		FOR i IN 1..dp_len LOOP
	    	entrada := dp[i];
	    	new_peso := entrada.peso_corrente + carga.peso;
	
		    IF new_peso > capacidade_maxima THEN
		      CONTINUE;
		    END IF;
		
		    -- Verifica se já existe new_peso no dp
		    existe := FALSE;
		    FOR j IN 1..array_length(dp, 1) LOOP
		      IF dp[j].peso_corrente = new_peso THEN
		        existe := TRUE;
		        EXIT;
		      END IF;
	    	END LOOP;
	
		    IF NOT existe THEN
		      dp := array_append(dp, ROW(new_peso, w, carga.id, carga.peso)::dp_type);
		      RAISE NOTICE 'Adicionando %', new_peso;
			END IF;
	  	END LOOP;

	END LOOP;

	RAISE NOTICE '%', dp;

	w := array_upper(dp, 1);
	peso := dp[w].carga_peso;
	peso_total := dp[w].peso_corrente;

	WHILE peso > 0 LOOP
		linha := ROW(dp[w].carga_id, dp[w].peso_corrente);
		selecionados := array_append(selecionados, linha);
		w := busca_binaria(dp, dp[w].peso_corrente - peso);
		peso := dp[w].carga_peso;
	END LOOP;

    cargas := selecionados;

	RETURN QUERY SELECT selecionados, peso_total;
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
