SET search_path TO afpg;

DROP TYPE IF EXISTS HEAP_E CASCADE;
CREATE TYPE HEAP_E AS (
	chave INTEGER,
	valor REAL
);

DROP TYPE IF EXISTS HEAP CASCADE;
CREATE TYPE HEAP AS (
	arr HEAP_E[]
);

CREATE OR REPLACE FUNCTION heap_new()
RETURNS HEAP AS $$
BEGIN
	RETURN ROW(ARRAY[]::HEAP_E[])::HEAP;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION heap_empty(heap HEAP)
RETURNS BOOLEAN AS $$
BEGIN
	RETURN array_length(heap.arr, 1) = 0;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION heap_top(heap HEAP)
RETURNS HEAP_E AS $$
BEGIN
	RETURN heap.arr[1];
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION heap_push(heap HEAP, chave INTEGER, prioridade REAL)
RETURNS HEAP AS $$
DECLARE
	i INTEGER;
	parent INTEGER;
BEGIN
	heap.arr := array_append(heap.arr, ROW(chave, prioridade)::HEAP_E);
	i := array_length(heap.arr, 1);

	WHILE i > 0 AND heap.arr[i] > heap.arr[i/2]
	LOOP
		heap.arr[i] = heap.arr[i/2];
		heap.arr[i/2] = ROW(chave, prioridade)::HEAP_E;
		i := i / 2;
	END LOOP;

	RETURN heap;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION heap_pop(heap HEAP)
RETURNS HEAP AS $$
DECLARE
BEGIN
	heap.arr[1] := heap.arr[array_length(heap.arr, 1)];
	heap.arr := trim_array(heap.arr, 1);
	heap := heap_heapify(heap, 1);
	RETURN heap;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION heap_heapify(heap HEAP, i INTEGER)
RETURNS HEAP AS $$
DECLARE
	l INTEGER := 2 * i;
	r INTEGER := 2 * i + 1;
	small INTEGER := i;
	temp HEAP_E;
BEGIN
	IF l <= array_length(heap.arr, 1) AND heap.arr[l] > heap.arr[i]
	THEN
        small := l;
    END IF;

	IF r <= array_length(heap.arr, 1) AND heap.arr[r] > heap.arr[small]
	THEN
        small := r;
	END IF;

    IF small != i
	THEN
		temp := heap.arr[i];
		heap.arr[i] := heap.arr[small];
		heap.arr[small] := temp;

        heap := heap_heapify(heap, small);
	END IF;

	RETURN heap;
END
$$ LANGUAGE plpgsql;

DROP TYPE IF EXISTS ALCANCAVEL;
CREATE TYPE ALCANCAVEL AS (
	porto CHAR(3),
	distancia_origem REAL,
	distancia_anterior REAL,
	anterior INTEGER,
	visitado BOOL
);

CREATE OR REPLACE FUNCTION enunciado1(
	codigo_navio INT,
	destino CHAR(3),
	distancia_maxima REAL DEFAULT 'infinity',
	desatracar_navio BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(
	passo INTEGER,
	de CHAR(3),
	para CHAR(3),
	distancia REAL,
	distancia_acumulada REAL
) AS $$
DECLARE
	navio RECORD;
	origem CHAR(3);

	heap HEAP := heap_new();
	heap_e HEAP_E;
	alcancaveis ALCANCAVEL ARRAY := '{}';
	
	atual ALCANCAVEL;
	atual_i INTEGER;
	proximo RECORD;
	proximo_i INTEGER;
	
	pilha INTEGER[] := '{}';
	passo INTEGER;
	distancia REAL;
	distancia_acumulada REAL := 0;
BEGIN
	SELECT * FROM Navio INTO navio
	WHERE codigo = codigo_navio;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Navio com código % não encontrado', codigo_navio;
		RETURN;
	END IF;

	IF navio.porto_id IS NULL THEN
		RAISE EXCEPTION 'Navio com código % não está em um porto', codigo_navio;
		RETURN;
	END IF;

	origem := navio.porto_id;

	-- EXECUÇÃO DIJKSTRA
	CREATE TEMP TABLE fila_prioridade (
		porto CHAR(3) PRIMARY KEY,
		distancia_origem REAL,
		anterior CHAR(3),
		visitado BOOL DEFAULT FALSE
	) ON COMMIT DROP;
	INSERT INTO fila_prioridade VALUES (origem, 0, NULL, FALSE);
	
	alcancaveis := array_append(alcancaveis, ROW(origem, 0, 0, NULL, FALSE)::ALCANCAVEL);
	heap := heap_push(heap, 1, 0);

	WHILE NOT heap_empty(heap)
	LOOP
		heap_e := heap_top(heap);
		atual_i := heap_e.chave;
		atual := alcancaveis[atual_i];
		heap := heap_pop(heap);
		
		IF atual.visitado THEN
			CONTINUE;
		END IF;
		atual.visitado := TRUE;

		IF atual.porto = destino THEN
			EXIT;  -- porto destino encontrado
		END IF;

		FOR proximo IN
			SELECT p.codigo, r.distancia
			FROM Porto p
				JOIN Rota r ON (r.destino = p.codigo)
			WHERE
				r.origem = atual.porto
		LOOP
			distancia := atual.distancia_origem + proximo.distancia;

			IF distancia > distancia_maxima THEN
				-- não excede a distância máxima
				CONTINUE;
			END IF;
		
			proximo_i := NULL;
			FOR i IN 1 .. array_length(alcancaveis, 1) LOOP
			    IF alcancaveis[i].porto = proximo.codigo THEN
			        proximo_i := i;
			        EXIT;
			    END IF;
			END LOOP;
			
			IF proximo_i IS NULL THEN
				-- primeiro caminho encontrado
			    alcancaveis := array_append(
					alcancaveis,
					ROW(proximo.codigo, distancia, proximo.distancia, atual_i, FALSE)::ALCANCAVEL
				);
			    proximo_i := array_length(alcancaveis, 1);
			ELSE
			    -- já tem um caminho de menor distância
			    IF alcancaveis[proximo_i].visitado OR
			       distancia >= alcancaveis[proximo_i].distancia_origem THEN
			        CONTINUE;
			    END IF;
			
			    -- encontrou um caminho melhor
			    alcancaveis[proximo_i].distancia_origem := distancia;
			    alcancaveis[proximo_i].distancia_anterior := proximo.distancia;
			    alcancaveis[proximo_i].anterior := atual_i;
			END IF;

			heap := heap_push(heap, proximo_i, distancia);
		END LOOP;
    END LOOP;

	-- RECONSTRUÇÃO DO CAMINHO
	IF alcancaveis[atual_i].porto != destino THEN
		RAISE NOTICE 'Rota do porto % para o porto % não encontrada', origem, destino;
		RETURN;
	END IF;

	IF desatracar_navio THEN
		UPDATE Navio
		SET porto_id = NULL
		WHERE codigo = codigo_navio;
	END IF;
	RAISE NOTICE 'O navio % saiu do porto %', codigo_navio, origem;

	WHILE atual_i IS NOT NULL LOOP
        pilha := array_prepend(atual_i, pilha);
		atual_i := alcancaveis[atual_i].anterior;
    END LOOP;

    FOR i IN 1..array_length(pilha, 1) - 1 LOOP
        passo := i;

		atual_i := pilha[i];
		atual := alcancaveis[atual_i];

		distancia_acumulada := distancia_acumulada + alcancaveis[pilha[i+1]].distancia_anterior;
		
		RETURN QUERY
			SELECT
	            passo,
	            atual.porto,
	            alcancaveis[pilha[i+1]].porto,
	            alcancaveis[pilha[i+1]].distancia_anterior,
	            distancia_acumulada;
	END LOOP;
END
$$ LANGUAGE plpgsql;

SELECT * FROM enunciado1(1, 'BUE', 26201, FALSE);
