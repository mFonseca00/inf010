-- Adição da coluna na tabela
ALTERALTER TABLE indice
ADD COLUMN idx numeric(8,3);

-- Função original que atualiza todos os registros
CREATE OR REPLACE FUNCTION
CalcularIdx()
RETURNS VOID
AS $$
BEGIN
UPDATE indice
SET idx = (((idh_educacao*idh_educacao)*idh_longevidade)/idh_geral);
END;
$$ LANGUAGE plpgsql;

-- Função V2 que calcula, atualiza e retorna o valor do idx para um registro específico
CREATE OR REPLACE FUNCTION
CalcularIdx(p_cod_municipio DECIMAL, p_ano DECIMAL, p_idh_educacao DECIMAL, p_idh_longevidade DECIMAL, p_idh_geral DECIMAL)
RETURNS DECIMAL(8,3)
AS $$
DECLARE
    novo_idx DECIMAL(8,3);
BEGIN
    novo_idx := (((p_idh_educacao * p_idh_educacao) * p_idh_longevidade) / p_idh_geral);
    
    UPDATE indice
    SET idx = novo_idx
    WHERE codmunicipio = p_cod_municipio AND ano = p_ano;
    
    RETURN novo_idx;
END;
$$ LANGUAGE plpgsql;

-- Função V3 que recalcula idx onde está diferente do que deveria
CREATE OR REPLACE FUNCTION
CalcularIdxInteligente()
RETURNS INTEGER
AS $$
DECLARE
    contador INTEGER;
BEGIN
    UPDATE indice 
    SET idx = (((idh_educacao * idh_educacao) * idh_longevidade) / idh_geral)
    WHERE ABS(COALESCE(idx, 0) - (((idh_educacao * idh_educacao) * idh_longevidade) / idh_geral)) > 0.001;
    
    GET DIAGNOSTICS contador = ROW_COUNT;
    RETURN contador;
END;
$$ LANGUAGE plpgsql
