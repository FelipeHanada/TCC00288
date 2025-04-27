SET search_path TO afpg;

CREATE OR REPLACE FUNCTION calcular_custo_movimentacao(p_volume REAL, p_categoria INTEGER) RETURNS REAL AS $$
DECLARE
    v_preco REAL;
    v_custo REAL;
BEGIN
    SELECT preco_para_movimentar
      INTO v_preco
      FROM CategoriaProduto
     WHERE id = p_categoria;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'CategoriaProduto com id % não encontrada', p_categoria;
    END IF;

    v_custo := p_volume * v_preco;
    RETURN v_custo;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION enunciado2(p_navio INTEGER) 
RETURNS TABLE(
    carga_id INTEGER,
    navio_id INTEGER,
    custo_unloading REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT Ca.id, p_navio, calcular_custo_movimentacao(Ca.peso, Pr.categoria_id)
    FROM Carga Ca JOIN Produto Pr ON Ca.produto_id = Pr.id
    WHERE Ca.navio_id = p_navio;
END;
$$ LANGUAGE plpgsql;

SELECT * from enunciado2(7);
